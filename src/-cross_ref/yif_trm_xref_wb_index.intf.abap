INTERFACE yif_trm_xref_wb_index
  PUBLIC.

  "! Includes of a class; empty if the class does not exist
  METHODS get_class_includes
    IMPORTING iv_class_name      TYPE seoclsname
    RETURNING VALUE(rt_includes) TYPE seoincl_t.

  "! Updates the navigation index of a workbench tree
  METHODS actualize
    IMPORTING iv_program TYPE program.

ENDINTERFACE.
