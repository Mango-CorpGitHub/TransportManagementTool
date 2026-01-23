CLASS ycl_trm_update_navigation_indx DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS update
      IMPORTING it_objects TYPE ycl_trm_cross_ref_analisys=>ty_t_objects.

  PRIVATE SECTION.
    DATA ai_t_already_updated_includes TYPE STANDARD TABLE OF program WITH DEFAULT KEY.

    METHODS call_wb_tree_actualize
      IMPORTING iv_program TYPE program.

    METHODS update_class
      IMPORTING iv_class_name TYPE string.

ENDCLASS.


CLASS ycl_trm_update_navigation_indx IMPLEMENTATION.
  METHOD update.

    LOOP AT it_objects ASSIGNING FIELD-SYMBOL(<ls_fragments>).

      IF <ls_fragments>-pgmid = 'R3TR' AND <ls_fragments>-obj_type = 'INTF'.
        call_wb_tree_actualize( CONV #( <ls_fragments>-obj_name ) ).
        CONTINUE.
      ENDIF.

      IF <ls_fragments>-pgmid = 'R3TR' AND <ls_fragments>-obj_type = 'CLASS'.
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
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lv_syntax_error TYPE c LENGTH 1.

    IF iv_program IS INITIAL.
      RETURN.
    ENDIF.

    IF line_exists( ai_t_already_updated_includes[ table_line = iv_program ] ).
      RETURN.
    ENDIF.

    CALL FUNCTION 'WB_TREE_ACTUALIZE'
      EXPORTING tree_name    = CONV program( |CP_{ iv_program }| )
      IMPORTING syntax_error = lv_syntax_error.

    INSERT iv_program INTO TABLE ai_t_already_updated_includes.
  ENDMETHOD.

  METHOD update_class.

    cl_oo_classname_service=>get_all_class_includes( EXPORTING  class_name    = CONV #( iv_class_name )
                                                     RECEIVING  result        = FINAL(lt_includes)
                                                     EXCEPTIONS no_such_class = 1
                                                                OTHERS        = 2 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT lt_includes ASSIGNING FIELD-SYMBOL(<lv_include>).

      call_wb_tree_actualize( <lv_include> ).

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
