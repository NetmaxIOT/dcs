public class Dcs.RefLinker : GLib.Object {


    private class Entry {

        /**
         * path to referenceing node
         */
        public string dest;

        /**
         * path to referenced node
         */
        public string src;

        /**
         * whether or not the reference is fulfilled
         */
        public bool satisfied;
    }

    public bool satisfied {
        get {
            bool result = true;
            foreach (var entry in table) {
                if (entry.satisfied == false) {
                    result = false;
                }
            }

            return result;
        }
    }

    public signal void progress (double value);

    public int nentries {
        get {
            return table.size;
        }
    }

    public int nsatisfied {
        get {
            int ret = 0;
            foreach (var entry in table) {
                if (entry.satisfied)
                    ret++;
            }

            return ret;
        }
    }

    private Gee.List<Entry?> table;

    private static Once<Dcs.RefLinker> _instance;

    /**
     * Instantiate singleton for reference linker.
     *
     * @return Instance of the reference linker.
     */
    public static unowned Dcs.RefLinker get_default () {
        return _instance.once (() => { return new Dcs.RefLinker (); });
    }

    construct {
        table = new Gee.ArrayList<Entry?> ();
    }

    /**
     * trim the leading '/' character from a path
     */
    private string trim (string str) {
        string ret = str;
        if (str.has_prefix ("/"))
            ret = str.substring (1, str.length - 1);

        return ret;
    }

    /**
     * Add a reference link to the reference table
     *
     * @param dest The absolute path to the referencing node
     * @param src The absolute path to the referenced node
     *
     * @return true if the reference was added, false otherwise
     */
    public bool add_reference (string dest, string src) {
        bool ref_added = false;
        var _dest = trim (dest);
        var _src = trim (src);

        foreach (var entry in table) {
            if ((entry.dest == _dest) && (entry.src == _src)) {
                ref_added = true;
            }
        }

        if (!ref_added) {
            Entry entry = new Entry ();
            entry.dest = _dest;
            entry.src = _src;
            ref_added = table.add (entry);
        }

        return ref_added;
    }

    /**
     * Remove a reference link from the reference table
     *
     * @param dest The absolute path of to the referencing node
     * @param src The absolute path to the refereced node
     *
     * @return true if the reference was removed, false otherwise
     */
    public bool remove_reference (string dest, string src) {
        bool result = false;
        var _dest = trim (dest);
        var _src = trim (src);

        var iter = table.iterator ();
        while (iter.has_next ()) {
            iter.next ();
            if ((iter.@get ().dest == _dest) && (iter.@get ().src == _src)) {
                iter.remove ();
                result = true;
            }
        }

        return result;

    }

    /**
     * Remove this referenced and referencing node path
     *
     * @param path The absolute path of the node to be removed
     *
     */
    public bool remove_path (string path) {
        bool result = false;
        var _path = trim (path);

        var iter = table.iterator ();
        while (iter.has_next ()) {
            iter.next ();
            if ((iter.@get ().src == _path) || (iter.@get ().dest == _path)) {
                iter.remove ();
                result = true;
            }
        }

        return result;
    }

    /**
     * Remove all references
     */
    public void clear () {
        table.clear ();
    }

    /**
     * Print the reference table. For debugging only.
     */
    public void print_table  () {
        stdout.printf ("dest\t\tsrc\t\tsatisfied\n");
        foreach (var entry in table) {
            stdout.printf ("%s\t\t%s\t\t%s\n", entry.dest, entry.src, entry.satisfied.to_string ());
        }
    }

    /**
     * TODO fill in
     *
     * Links references from the reference table to nodes
     *
     * @param node A Dcs.Node to be processed
     *
     * @return true if all references are satisfied otherwise false
     */
    public void process_node (Dcs.Node node) throws Dcs.NodeError {
        foreach (var entry in table) {
            if (!entry.satisfied) {
                Dcs.Node nd;
                Dcs.Node src;
                int index = table.index_of (entry);
                try {
                    nd = node.retrieve (entry.dest);
                    src = node.retrieve (entry.src);
                    if ((nd != null) && (src != null)) {
                        nd.add_reference (src);
                        entry.satisfied = true;
                        progress ((double)index / (double)table.size);
                    }
                } catch (Dcs.NodeError e) {
                    throw e;
                }
            }
        }
        // ideas
        // - construct table of nodes and references
        //   take table and turn reference to absolute path
        //   get node at path as week ref
        /*
         *foreach (var node in nodes) {
         *    node.reference_added.connect (do_something);
         *    foreach (var @ref in node.get_references ()) {
         *        // not sure what to do
         *    }
         *}
         */
    }
}
