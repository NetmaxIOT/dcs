public abstract class Dcs.RefLinkerTestsBase : Dcs.TestCase {

    protected Dcs.RefLinker linker;
    protected Dcs.Node node0;
    protected Dcs.Node node00;
    protected Dcs.Node node000;
    protected Dcs.Node node001;
    protected Dcs.Node node01;
    protected Dcs.Node node010;
    protected Dcs.Node node011;

    public RefLinkerTestsBase (string name) {
        base (name);
    }
}

public class Dcs.RefLinkerTests : Dcs.RefLinkerTestsBase {

    private const string class_name = "DcsRefLinker";

    public RefLinkerTests () {
        base (class_name);
        add_test (@"[$class_name] Test clear reference table", test_clear);
        add_test (@"[$class_name] Test add to reference table", test_add_reference);
        add_test (@"[$class_name] Test remove from reference table", test_remove_reference);
        add_test (@"[$class_name] Test remove node from reference table", test_remove_path);
        add_test (@"[$class_name] Test process configuration nodes", test_process_nodes);
        /*add_test (@"[$class_name] Test progress signalling", test_progress);*/
    }

    public override void set_up () {
        linker = Dcs.RefLinker.get_default ();
        build_node ();
    }

    public override void tear_down () {
        linker = null;
    }

   /**
    * Node tree:
    *
    *                    node0
    *            __________|_________
    *           |                    |
    *         node00               node01
    *       ____|____            ____|____
    *      |         |          |         |
    *   node000   node001    node010   node011
    *
    *
    * Node references:
    *
    *    node00  -> node01, node010, node011
    *    node000 -> node01, node010, node011
    *    node001 -> node01, node010, node011
    *    node01  -> node00, node000, node001
    *    node010 -> node00, node000, node001
    *    node011 -> node00, node000, node001
    *
    */
    public void build_node () {
        node0 = new Dcs.Test.Node ("node0");
        node00 = new Dcs.Test.Node ("node00");
        node000 = new Dcs.Test.Node ("node000");
        node001 = new Dcs.Test.Node ("node001");
        node01 = new Dcs.Test.Node ("node01");
        node010 = new Dcs.Test.Node ("node010");
        node011 = new Dcs.Test.Node ("node011");

        node0.add (node00);
        node0.add (node01);
        node00.add (node000);
        node00.add (node001);
        node01.add (node010);
        node01.add (node011);
    }

    public void add_references () {
        linker.add_reference ("/node0/node00", "/node0/node01");
        linker.add_reference ("/node0/node00", "/node0/node01/node010");
        linker.add_reference ("/node0/node00", "/node0/node01/node011");

        linker.add_reference ("/node0/node00/node000", "/node0/node01");
        linker.add_reference ("/node0/node00/node000", "/node0/node01/node010");
        linker.add_reference ("/node0/node00/node000", "/node0/node01/node011");

        linker.add_reference ("/node0/node00/node001", "/node0/node01");
        linker.add_reference ("/node0/node00/node001", "/node0/node01/node010");
        linker.add_reference ("/node0/node00/node001", "/node0/node01/node011");

        linker.add_reference ("/node0/node01", "/node0/node00");
        linker.add_reference ("/node0/node01", "/node0/node00/node000");
        linker.add_reference ("/node0/node01", "/node0/node00/node001");

        linker.add_reference ("/node0/node01/node010", "/node0/node00");
        linker.add_reference ("/node0/node01/node010", "/node0/node00/node000");
        linker.add_reference ("/node0/node01/node010", "/node0/node00/node001");

        linker.add_reference ("/node0/node01/node011", "node0/node00");
        linker.add_reference ("/node0/node01/node011", "node0/node00/node000");
        linker.add_reference ("/node0/node01/node011", "node0/node00/node001");
    }

    public void test_clear () {
        linker.clear ();
        add_references ();
        assert (linker.nentries == 18);
        linker.clear ();
        assert (linker.nentries == 0);
    }

    public void test_add_reference () {
        linker.clear ();
        linker.add_reference ("/node0/node00", "/node0/node01");
        assert (linker.nentries == 1);
        linker.add_reference ("/node0/node00", "/node0/node01");
        assert (linker.nentries == 1);
    }

    public void test_remove_reference () {
        linker.clear ();
        linker.add_reference ("/node0/node00", "/node0/node01");
        assert (linker.nentries == 1);
        linker.remove_reference ("/node0/node00", "/node0/node01");
        assert (linker.nentries == 0);
    }

    public void test_remove_path () {
        linker.clear ();
        add_references ();
        assert (linker.nentries == 18);
        linker.remove_path ("/node0/node00");
        assert (linker.nentries == 12);
    }

    public void test_process_nodes () {
        linker.clear ();
        add_references ();
        /* Process node */
        linker.process_node (node0);

        /* Check if all references are satisfied */
        assert (linker.satisfied);

        /* Verify that all references are satisfied */
        assert (node00.references.contains (node01));
        assert (node00.references.contains (node010));
        assert (node00.references.contains (node011));
        assert (node00.references.size == 3);

        assert (node000.references.contains (node01));
        assert (node000.references.contains (node010));
        assert (node000.references.contains (node011));
        assert (node000.references.size == 3);

        assert (node001.references.contains (node01));
        assert (node001.references.contains (node010));
        assert (node001.references.contains (node011));
        assert (node001.references.size == 3);

        assert (node01.references.contains (node00));
        assert (node01.references.contains (node000));
        assert (node01.references.contains (node001));
        assert (node01.references.size == 3);

        assert (node010.references.contains (node00));
        assert (node010.references.contains (node000));
        assert (node010.references.contains (node001));
        assert (node010.references.size == 3);

        assert (node011.references.contains (node00));
        assert (node011.references.contains (node000));
        assert (node011.references.contains (node001));
        assert (node011.references.size == 3);

        /*Test invalid linking */
/*
 *
 *        linker.add_reference ("node011", "node0/node00/nodeFoo");
 *        try {
 *            linker.process_node (node0);
 *        } catch (Dcs.NodeError e) {
 *            assert (!linker.satisfied);
 *            assert (e is Dcs.NodeError.NULL_REFERENCE);
 *        }
 */
    }

    public async void test_progress () {
    }
}
