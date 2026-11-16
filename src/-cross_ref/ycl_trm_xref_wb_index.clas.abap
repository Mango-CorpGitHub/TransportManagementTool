CLASS ycl_trm_xref_wb_index DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_trm_xref_wb_index.

ENDCLASS.


CLASS ycl_trm_xref_wb_index IMPLEMENTATION.

  METHOD yif_trm_xref_wb_index~get_class_includes.
    cl_oo_classname_service=>get_all_class_includes( EXPORTING  class_name    = iv_class_name
                                                     RECEIVING  result        = rt_includes
                                                     EXCEPTIONS no_such_class = 1
                                                                OTHERS        = 2 ).
    IF sy-subrc <> 0.
      CLEAR rt_includes.
    ENDIF.
  ENDMETHOD.

  METHOD yif_trm_xref_wb_index~actualize.
    DATA lv_syntax_error TYPE c LENGTH 1 ##NEEDED.

    CALL FUNCTION 'WB_TREE_ACTUALIZE'
      EXPORTING tree_name    = iv_program
      IMPORTING syntax_error = lv_syntax_error.
  ENDMETHOD.

ENDCLASS.
