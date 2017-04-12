public class Dcs.RefLinker : GLib.Object {

    // node id | ref | path | satisfied

    private class Entry {
        public string path;          // path to node
        public string reference;        // path to reference node
        public bool satisfied;     // whether or not the reference is fulfilled
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
     * Add a reference link to the reference table
     *
     * @param path The absolute path of to the referencing node
     * @param reference The absolute path to the refereced node
     */
    public void add_entry (string path, string reference) {
        Entry entry = new Entry ();
        entry.path = path;
        entry.reference = reference;
        entry.satisfied = false;
        table.add (entry);
    }

    /**
     * Print the reference table.
     */
    public void print_table  () {
        stdout.printf ("path\t\treference\t\tsatisfied\n");
        foreach (var entry in table) {
            stdout.printf ("%s\t\t%s\t\t%s\n", entry.path, entry.reference, entry.satisfied.to_string ());
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
    public bool process_node (Dcs.Node node) throws Dcs.NodeError {
        var satisfied = true;

        foreach (var entry in table) {
            if (!entry.satisfied) {
                Dcs.Node nd;
                Dcs.Node reference;
                try {
                    nd = node.retrieve (entry.path);
                    try {
                        reference = node.retrieve (entry.reference);
                    } catch (Dcs.NodeError e) {
                        throw e;
                    }

                    if ((nd != null) && (reference != null)) {
                        nd.add_reference (reference);
                        entry.satisfied = true;
                    } else {
                        satisfied = false;
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

         return satisfied;
    }
}
