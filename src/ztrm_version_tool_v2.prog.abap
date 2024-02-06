*&---------------------------------------------------------------------*
*& Report YAAG_VERSION_TOOL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztrm_version_tool_v2.

CALL TRANSACTION 'YTRM_VERSION_TOOL_V2'.

*INCLUDE ztrm_version_tool_v2_clas.
*
*DATA lv_trkorr TYPE e070-trkorr.
*DATA lr_user   TYPE lcl_sh_for_transport_request=>ty_r_users.
*DATA lv_trtext TYPE e07t-as4text.
*
*SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
*  SELECTION-SCREEN BEGIN OF LINE.
*    SELECTION-SCREEN COMMENT (28) FOR FIELD s_trkorr.
*    SELECT-OPTIONS: s_trkorr FOR lv_trkorr NO INTERVALS.
*    SELECTION-SCREEN POSITION 64.
*    SELECTION-SCREEN PUSHBUTTON (8) f_ses USER-COMMAND f_ses.
*    SELECTION-SCREEN POSITION 74.
*    SELECTION-SCREEN PUSHBUTTON (4) see_tr USER-COMMAND see_tr.
*  SELECTION-SCREEN END OF LINE.
*  PARAMETERS p_descr TYPE e07t-as4text.
*  SELECTION-SCREEN BEGIN OF LINE.
*    SELECTION-SCREEN COMMENT (31) FOR FIELD p_owner.
*    PARAMETERS p_owner TYPE sy-uname.
*    PARAMETERS p_name TYPE user_addr-name_textc.
*  SELECTION-SCREEN END OF LINE.
*  PARAMETERS p_usr TYPE abap_bool AS CHECKBOX USER-COMMAND frad1 DEFAULT abap_true.
*
*SELECTION-SCREEN END OF BLOCK b1.
*
*SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
*  PARAMETERS p_comp TYPE abap_bool AS CHECKBOX USER-COMMAND frad1 DEFAULT abap_true.
*  PARAMETERS rb_q   RADIOBUTTON GROUP rad USER-COMMAND frad1 DEFAULT 'X'.
*  PARAMETERS rb_p   RADIOBUTTON GROUP rad.
*  SELECTION-SCREEN: BEGIN OF LINE.
*    SELECTION-SCREEN POSITION 5.
*    SELECTION-SCREEN PUSHBUTTON (25) comm2 USER-COMMAND to_s4d.
*    PARAMETERS p_tos4d TYPE e070-trkorr.
*  SELECTION-SCREEN: END OF LINE.
*  PARAMETERS rb_oth RADIOBUTTON GROUP rad.
*  PARAMETERS p_dest TYPE rfcdest.
*SELECTION-SCREEN END OF BLOCK b2.
*
*INITIALIZATION.
*  comm2 = TEXT-002.
*  see_tr = icon_display.
*  f_ses = |{ icon_search } SES|.
*  s_trkorr-sign = 'I'.
*  s_trkorr-option = 'EQ'.
*  s_trkorr-low = |{ sy-sysid }*|.
*  APPEND s_trkorr TO s_trkorr.
*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_trkorr-low.
*  CLEAR lr_user.
*  IF p_usr = abap_true.
*    lr_user = VALUE #( ( sign = if_fsbp_const_range=>sign_include
*                         option = if_fsbp_const_range=>option_equal
*                         low = sy-uname ) ).
*  ENDIF.
*  DATA(lv_selected_line) = NEW lcl_sh_for_transport_request( )->show( lr_user ).
*  IF lv_selected_line IS NOT INITIAL.
*    s_trkorr-low = lv_selected_line.
*  ENDIF.
*
*AT SELECTION-SCREEN OUTPUT.
*
*  IF rb_oth = abap_false.
*    CLEAR p_dest.
*  ENDIF.
*
*  LOOP AT SCREEN.
*    IF screen-name = 'P_TOS4D' OR
*       screen-name = 'P_TOS4Q' OR
*       screen-name = 'P_DESCR' OR
*       screen-name = 'P_OWNER' OR
*       screen-name = 'P_NAME'.
*      screen-input = 0.
*    ENDIF.
*
*    IF screen-name CS 'COMM2' OR screen-name CS 'P_TOS4D' OR screen-name cs 'RB_OTH'.
**      screen-active = COND #( WHEN rb_p = abap_false THEN 0 ELSE 1 ).
*      screen-active = 0.
*    ENDIF.
*
*    IF screen-name CS 'P_DEST'.
*      screen-input = COND #( WHEN rb_oth = abap_false THEN 0 ELSE 1 ).
*      screen-active = COND #( WHEN rb_oth = abap_false THEN 0 ELSE 1 ).
*      screen-required = COND #( WHEN rb_oth = abap_false THEN 0 ELSE 2 ).
*    ENDIF.
*
*    MODIFY SCREEN.
*  ENDLOOP.
*
*AT SELECTION-SCREEN.
*
*  CASE sy-ucomm.
*
*    WHEN 'TO_S4D'.
*
*      DATA lv_answer TYPE char01.
*      CALL FUNCTION 'POPUP_TO_CONFIRM'
*        EXPORTING
*          titlebar              = 'Generate S4D version'
*          text_question         = |A new TR will be created and released with the current version of the objects included in the selected TRs|
*          text_button_1         = 'Yes'
*          text_button_2         = 'No'
*          default_button        = '2'
*          display_cancel_button = ''
*        IMPORTING
*          answer                = lv_answer.
*      IF lv_answer = '2'. " No
*        RETURN.
*      ENDIF.
*
*      TRY.
*          DATA(lo_log) = zcl_log=>new( ).
*          p_tos4d = ztrm_cre_transport_of_copy=>create( im_o_parent_logger = lo_log )->execute(
*                        iv_description        = |COPY S4D Version|
*                        it_transport_requests = CORRESPONDING #( s_trkorr[] ) ).
*          lo_log->display_popup( ).
*        CATCH cx_static_check INTO DATA(lo_error).
*          MESSAGE lo_error->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
*      ENDTRY.
*
*    WHEN 'SEE_TR'.
*      lcl_selected_transport_request=>create( s_trkorr[] )->display( ).
*
*    WHEN 'F_SES'.
*      DATA(lt_ses_request) = lcl_find_request_by_ses=>create( )->execute( ).
*      IF NOT line_exists( lt_ses_request[ 1 ] ).
*        RETURN.
*      ENDIF.
*      s_trkorr[] = VALUE #( FOR lv_ses_request IN lt_ses_request ( sign = 'I' option = 'EQ' low = lv_ses_request ) ).
*
*      DATA(lt_transport_requests) = ztrm_get_tr_data=>create( )->find( CORRESPONDING #( s_trkorr[] ) ).
*      IF lt_transport_requests IS NOT INITIAL.
*        p_descr = lt_transport_requests[ 1 ]-as4text.
*        p_owner = lt_transport_requests[ 1 ]-as4user.
*        p_name  = lt_transport_requests[ 1 ]-name.
*      ELSE.
*        CLEAR p_descr.
*        CLEAR p_owner.
*        CLEAR p_name.
*      ENDIF.
*
*    WHEN OTHERS.
*      lt_transport_requests = ztrm_get_tr_data=>create( )->find( CORRESPONDING #( s_trkorr[] ) ).
*      IF lt_transport_requests IS NOT INITIAL.
*        p_descr = lt_transport_requests[ 1 ]-as4text.
*        p_owner = lt_transport_requests[ 1 ]-as4user.
*        p_name  = lt_transport_requests[ 1 ]-name.
*      ELSE.
*        CLEAR p_descr.
*        CLEAR p_owner.
*        CLEAR p_name.
*      ENDIF.
*  ENDCASE.
*
*START-OF-SELECTION.
*
*  DATA lv_rfc_compare_destination TYPE rfcdest.
*  CASE abap_true.
*    WHEN rb_q.
*      lv_rfc_compare_destination = zcl_trm_transport_request=>get_customizing( )-rfc_to_quality. "lcl_app=>rfc_destintations-quality.
*    WHEN rb_p.
*      lv_rfc_compare_destination = zcl_trm_transport_request=>get_customizing( )-rfc_to_productive. "lcl_app=>rfc_destintations-productive.
*    WHEN rb_oth.
*      lv_rfc_compare_destination = p_dest.
*  ENDCASE.
*
*  IF lv_rfc_compare_destination IS INITIAL.
*    MESSAGE 'RFC destintation is mandatory' TYPE 'S' DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.
*
*  DATA(lt_transport_requests) = ztrm_get_tr_data=>create( )->find( CORRESPONDING #( s_trkorr[] ) ).
*  IF lines( lt_transport_requests ) = 0.
*    MESSAGE 'No request found' TYPE 'S' DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.
*
*  SELECT SINGLE @abap_true FROM @lt_transport_requests AS transport_request
*    WHERE as4user <> @sy-uname
*    INTO @DATA(lv_request_is_not_from_user).
*  IF p_usr = abap_true AND lv_request_is_not_from_user = abap_true.
*    MESSAGE |At least one request is not from user { sy-uname }| TYPE 'S' DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.
*
*  NEW lcl_app( NEW lcl_alv_qry( ) )->run(
*    ir_transport_request = s_trkorr[]
*    iv_tr_descr     = p_descr
*    iv_compare      = p_comp
*    iv_user_request = COND #( WHEN p_usr = abap_true THEN sy-uname ELSE space )
*    iv_rfc_compare_destination = lv_rfc_compare_destination ).
*
*  WRITE space.
