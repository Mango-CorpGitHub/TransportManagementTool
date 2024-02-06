*&---------------------------------------------------------------------*
*& Include ytrm_version_tool_v2_sc
*&---------------------------------------------------------------------*

DATA go_app TYPE REF TO lcl_app.
DATA lv_rfc_compare_destination TYPE rfcdest.

MODULE run_app OUTPUT.

  IF go_app IS BOUND.
    RETURN.
  ENDIF.

  cl_gui_container=>default_screen->link(
    repid = sy-repid
    dynnr = '0100' ).

  go_app = NEW lcl_app( NEW lcl_alv_qry( ) ).

  go_app->run(
      it_transport_request = gt_transport_requests
      ir_transport_request = s_trkorr[]
      iv_tr_descr     = p_descr
      iv_compare      = p_comp
      iv_user_request = COND #( WHEN p_usr = abap_true THEN sy-uname ELSE space )
      iv_rfc_compare_destination = lv_rfc_compare_destination ).

ENDMODULE.

MODULE exit_command.

  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL' OR '%EX' OR 'RW'.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.

CLASS lcl_selection_screen DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS initialization.

    CLASS-METHODS at_selection_screen_output.

    CLASS-METHODS at_selection_screen.

    CLASS-METHODS start_of_selection.

    CLASS-METHODS on_value_request_for_s_trkorr.

  PRIVATE SECTION.

    CLASS-METHODS loop_at_screen
      IMPORTING
                is_screen        TYPE screen
      RETURNING VALUE(rs_screen) TYPE screen.

    CLASS-METHODS execute_f_ses.

ENDCLASS.

CLASS lcl_selection_screen IMPLEMENTATION.

  METHOD at_selection_screen.

    CASE sy-ucomm.

      WHEN 'SEE_TR'.
        DATA(lt_transport_requests) = ycl_trm_transport_request=>get_by_attributes( im_s_query_by_attr = VALUE #( transportrequestid = s_trkorr[] ) ).

        lcl_selected_transport_request=>create( )->display( lt_transport_requests ).

      WHEN 'F_SES'.
        execute_f_ses( ).

      WHEN OTHERS.

        lt_transport_requests = ycl_trm_transport_request=>get_by_attributes( im_s_query_by_attr = VALUE #( transportrequestid = s_trkorr[] ) ).
        IF lt_transport_requests IS NOT INITIAL.
          p_descr = lt_transport_requests[ 1 ]->get_description( ).
          p_owner = lt_transport_requests[ 1 ]->get_owner( IMPORTING ex_name = p_name ).
        ELSE.
          CLEAR p_descr.
          CLEAR p_owner.
          CLEAR p_name.
        ENDIF.

    ENDCASE.

  ENDMETHOD.

  METHOD on_value_request_for_s_trkorr.

    CLEAR lr_user.
    IF p_usr = abap_true.
      lr_user = VALUE #( ( sign = if_fsbp_const_range=>sign_include
                           option = if_fsbp_const_range=>option_equal
                           low = sy-uname ) ).
    ENDIF.
    DATA(lt_selected_lines) = NEW lcl_sh_for_transport_request( )->show( lr_user ).
    IF line_exists( lt_selected_lines[ 1 ] ).
      s_trkorr[] = VALUE #( FOR lv_selected_lines IN lt_selected_lines ( sign = 'I' option = 'EQ' low = lv_selected_lines ) ).
      s_trkorr-low = s_trkorr[ 1 ]-low.
    ENDIF.

  ENDMETHOD.

  METHOD at_selection_screen_output.

    LOOP AT SCREEN.

      screen = loop_at_screen( screen ).

      MODIFY SCREEN.

    ENDLOOP.

  ENDMETHOD.

  METHOD initialization.

    see_tr = icon_display.
    f_ses = |{ icon_search } SES|.
    s_trkorr-sign = 'I'.
    s_trkorr-option = 'EQ'.
    s_trkorr-low = |{ sy-sysid }*|.
    APPEND s_trkorr TO s_trkorr.

    go_log = ycl_trm_logger=>new( ).

  ENDMETHOD.

  METHOD start_of_selection.

*    DATA lv_rfc_compare_destination TYPE rfcdest.
    CASE abap_true.
      WHEN rb_q.
        lv_rfc_compare_destination = ycl_trm_transport_request=>get_customizing( )-rfc_to_quality.
      WHEN rb_p.
        lv_rfc_compare_destination = ycl_trm_transport_request=>get_customizing( )-rfc_to_productive.
    ENDCASE.

    IF lv_rfc_compare_destination IS INITIAL.
      MESSAGE 'RFC destintation is mandatory' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    gt_transport_requests = ycl_trm_transport_request=>get_by_attributes( im_s_query_by_attr = VALUE #( transportrequestid = s_trkorr[] )
                                                                          im_o_parent_logger = go_log ).

    IF lines( gt_transport_requests ) = 0.
      MESSAGE 'No request found' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF p_usr = abap_true.

      LOOP AT gt_transport_requests ASSIGNING <lo_transport_request>.
        IF <lo_transport_request>->get_owner(  ) NE sy-uname.
          MESSAGE |At least one request is not from user { sy-uname }| TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      ENDLOOP.

      DATA(lv_tasks_of_other_user) = abap_false.
      LOOP AT gt_transport_requests ASSIGNING <lo_transport_request>.

        LOOP AT <lo_transport_request>->get_tasks(  ) ASSIGNING FIELD-SYMBOL(<lo_task>).
          IF <lo_task>->get_owner(  ) NE sy-uname.
            lv_tasks_of_other_user = abap_true.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lv_tasks_of_other_user = abap_true.
          MESSAGE |At least one task is not from user { sy-uname }| TYPE 'I'.
          EXIT.
        ENDIF.
      ENDLOOP.

    ENDIF.

    CLEAR go_app.
    CALL SCREEN 100.

*    NEW lcl_app( NEW lcl_alv_qry( ) )->run(
*      it_transport_request = gt_transport_requests
*      ir_transport_request = s_trkorr[]
*      iv_tr_descr     = p_descr
*      iv_compare      = p_comp
*      iv_user_request = COND #( WHEN p_usr = abap_true THEN sy-uname ELSE space )
*      iv_rfc_compare_destination = lv_rfc_compare_destination ).
*
*    WRITE space.

  ENDMETHOD.

  METHOD loop_at_screen.

    rs_screen = is_screen.

    IF rs_screen-name = 'P_DESCR' OR
       rs_screen-name = 'P_OWNER' OR
       rs_screen-name = 'P_NAME'.
      rs_screen-input = 0.
    ENDIF.

    IF rs_screen-name = 'F_SES'.
      rs_screen-active = 0.
    ENDIF.

  ENDMETHOD.


  METHOD execute_f_ses.
    " Enchance with button functionality...

  ENDMETHOD.

ENDCLASS.
