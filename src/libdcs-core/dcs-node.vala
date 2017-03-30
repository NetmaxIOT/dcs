public errordomain Dcs.NodeError {
    PARENT_EXISTS,
    CIRCULAR_REFERENCE
}

public abstract class Dcs.Node : Gee.TreeMap<string, Dcs.Node>,
                                 Dcs.Object, Dcs.Serializable, Dcs.RefContainer {

    private bool verbose = false;

    /**
     * {@inheritDoc}
     */
    public virtual string id { get; set; }

    /**
     * {@inheritDoc}
     */
    public virtual string serialize () throws GLib.Error {
        return "{}";
    }

    /**
     * {@inheritDoc}
     */
    public virtual void deserialize (string data) throws GLib.Error {
        /* XXX do something */
    }

    /**
     * {@inheritDoc}
     */
    protected virtual Gee.List<unowned Dcs.Node> references { get; private set; }

    /**
     * Parent of the node, null if this is the root.
     */
    public Dcs.Node parent { get; set; default = null; }

    /**
     * Emitted whenever an node as been added.
     *
     * @param id the ID of the node that was added
     */
    public signal void node_added (string id);

    /**
     * Emitted whenever an node as been removed.
     *
     * @param id the ID of the node that was removed
     */
    public signal void node_removed (string id);

    /**
     * Used by implementing classes to request a child node for addition.
     *
     * @param id the ID of the node that was requested
     */
    public signal void request_node (string id);

    /**
     * {@inheritDoc}
     */
    public override void @set (string key, Dcs.Node node) {
        try {
            add (node);
        } catch (Dcs.NodeError e) {
            debug (e.message);
        }
    }

    /**
     * {@inheritDoc}
     */
    public override bool @unset (string key, out Dcs.Node node) {
        bool ret;

        try {
            remove (node);
            ret = true;
        } catch (Dcs.NodeError e) {
            debug (e.message);
            ret = false;
        }

        return ret;
    }

    /**
     * Increase to_string verbosity to display parent properties.
     *
     * @param value `true` to print parent properties, `false` to hide them.
     */
    public void set_print_verbosity (bool value) {
        verbose = value;
    }

    /**
     * Add a node.
     *
     * @param node a node to be added
     */
    public virtual void add (Dcs.Node node) throws Dcs.NodeError {
        var descendants = node.get_descendants (typeof (Dcs.Node));

        if (node.parent != null) {
            throw new Dcs.NodeError.PARENT_EXISTS (
                "Node already has a parent");
        } else if (descendants.contains (this)) {
            /* XXX is this accurate? what if a descendant has the same ID?
             * maybe this should be based off the path instead */
            throw new Dcs.NodeError.CIRCULAR_REFERENCE (
                "Node contains itself as a descendant");
        } else {
            base.@set (node.id, node);
            node.parent = this;
            node_added (node.id);
        }
    }

    /**
     * Remove a node.
     *
     * @param node node to remove from the list
     */
    public virtual void remove (Dcs.Node node) {
        Dcs.Node value;
        base.unset (node.id, out value);
        value.parent = null;
        node_removed (node.id);
    }

    /**
     * Retrieves a list of all nodes of a certain type.
     *
     * {{{
     *  // XXX TBD Dcs.UI does not use node yet. It still uses Dcs.Container
     *  var pg_list = node.get_descendants (typeof (Dcs.UI.Page));
     * }}}
     *
     * @param type class type to retrieve
     *
     * @return list of all nodes of a certain class type
     */
    public virtual Gee.ArrayList<Dcs.Node> get_descendants (Type type) {
        var list = new Gee.ArrayList<Dcs.Node> ();
        foreach (var node in values) {
            if (node.get_type ().is_a (type)) {
                list.add (node);
            }
            if (node is Dcs.Node) {
                var sub_list = (node as Dcs.Node).get_descendants (type);
                foreach (var sub_node in sub_list) {
                    if (sub_node.get_type ().is_a (type)) {
                        list.add (sub_node);
                    }
                }
            }
        }
        return list;
    }

    /**
     * Retrieve a map of the children of a certain type.
     *
     * {{{
     *  // XXX TBD Dcs.UI does not use node yet. It still uses Dcs.Container
     *  var children = node.get_children (typeof (Dcs.UI.Box));
     * }}}
     *
     * @param type class type to retrieve
     *
     * @return list of all nodes of a certain class type
     */
    public virtual Gee.ArrayList<Dcs.Node> get_children (Type type) {
        Gee.ArrayList<Dcs.Node> list = new Gee.ArrayList<Dcs.Node> ();
        foreach (var node in values) {
            if (node.get_type ().is_a (type)) {
                list.add (node);
            }
        }
        return list;
    }

    /**
     * Moves a node value from this node to another.
     */
    private void reparent (Dcs.Node? new_parent) {
        if (parent != null) {
            parent.remove (this);
            new_parent.add (this);
        }
    }

    /**
     * Recursively print the contents of the nodes map.
     *
     * @param depth current level of the node tree
     */
    public virtual void print_node (int depth = 0) {
        foreach (var node in values) {
            string indent = string.nfill (depth * 2, ' ');
            debug ("%s[%s: %s]", indent, node.get_type ().name (), node.id);
            if (node is Dcs.Node) {
                (node as Dcs.Node).print_node (depth + 1);
            }
        }
    }

    /**
     * Dump node data to a string
     *
     * Example output:
     *
     * {{{
     * """
     * FooNode (foo0)
     * --------------
     * Properties
     *   val-a:  1
     *   val-b:  one
     *   val-c:  true
     * References:
     *   /foo1
     *   /foo2
     * Objects:
     *   foo-a
     *   foo-b
     *   foo-c
     * """
     * }}}
     *
     * @return A string containing information about this node
     */
    public virtual string to_string () {
        var builder = new StringBuilder ();

        var type = get_type ();
        var parent_type = type.parent ();
        builder.append (type.name () + " (" + id + ")\n");
        for (var i = 0; i < 48; i++) {
            builder.append ("-");
        }
        builder.append ("\n\n Properties:\n\n");

        var ocl = (ObjectClass) type.class_ref ();
        var parent_ocl = (ObjectClass) parent_type.class_ref ();
        foreach (var spec in ocl.list_properties ()) {
            if (ParamFlags.READABLE in spec.flags) {
                Value value = Value (spec.value_type);
                get_property (spec.get_name (), ref value);
                var str = "";

                if (spec.value_type == typeof (string)) {
                    str = value.get_string ();
                } else if (spec.value_type == typeof (int)) {
                    str = value.get_int ().to_string ();
                } else if (spec.value_type == typeof (double)) {
                    str = value.get_double ().to_string ();
                } else if (spec.value_type == typeof (bool)) {
                    str = value.get_boolean ().to_string ();
                } else {
                    str = "(unknown)";
                }

                var prop = "%20s : %-20s\n".printf (spec.get_name (), str);

                if (verbose) {
                    builder.append (prop);
                } else {
                    if (parent_ocl.find_property (spec.get_name ()) == null) {
                        builder.append (prop);
                    }
                }
            }
        }

        return builder.str;
    }
}