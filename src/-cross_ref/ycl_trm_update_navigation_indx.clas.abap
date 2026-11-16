CLASS ycl_trm_update_navigation_indx DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! @parameter io_wb_index | Workbench navigation index access; real one if not supplied
    METHODS constructor
      IMPORTING io_wb_index TYPE REF TO yif_trm_xref_wb_index OPTIONAL.

    METHODS update
      IMPORTING it_objects TYPE ycl_trm_cross_ref_analisys=>ty_t_objects.

  PRIVATE SECTION.
    DATA ai_o_wb_index                 TYPE REF TO yif_trm_xref_wb_index.
    DATA ai_t_already_updated_includes TYPE STANDARD TABLE OF program WITH DEFAULT KEY.

    METHODS call_wb_tree_actualize
      IMPORTING iv_program TYPE program.

    METHODS update_class
      IMPORTING iv_class_name TYPE string.

ENDCLASS.


CLASS ycl_trm_update_navigation_indx IMPLEMENTATION.
  METHOD constructor.
    ai_o_wb_index = COND #( WHEN io_wb_index IS BOUND THEN io_wb_index ELSE NEW ycl_trm_xref_wb_index( ) ).
  ENDMETHOD.

  METHOD update.

    LOOP AT it_objects ASSIGNING FIELD-SYMBOL(<ls_fragments>).

      IF <ls_fragments>-pgmid = 'R3TR' AND <ls_fragments>-obj_type = 'INTF'.
        call_wb_tree_actualize( CONV #( |CP_{ <ls_fragments>-obj_name }| ) ).
        CONTINUE.
      ENDIF.

      IF <ls_fragments>-pgmid = 'R3TR' AND <ls_fragments>-obj_type = 'CLAS'.
        update_class( CONV #( <ls_fragments>-obj_name ) ).
        CONTINUE.
      ENDIF.

      IF <ls_fragments>-pgmid = 'LIMU' AND <ls_fragments>-obj_type = 'METH'.
        update_class( CONV #( <ls_fragments>-obj_name(30) ) ).
        CONTINUE.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD call_wb_tree_actualize.
    IF iv_program IS INITIAL.
      RETURN.
    ENDIF.

    IF line_exists( ai_t_already_updated_includes[ table_line = iv_program ] ).
      RETURN.
    ENDIF.

    ai_o_wb_index->actualize( iv_program ).

    INSERT iv_program INTO TABLE ai_t_already_updated_includes.
  ENDMETHOD.

  METHOD update_class.

    FINAL(lt_includes) = ai_o_wb_index->get_class_includes( CONV #( iv_class_name ) ).

    LOOP AT lt_includes ASSIGNING FIELD-SYMBOL(<lv_include>).

      call_wb_tree_actualize( |CP_{ <lv_include> }| ).

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
