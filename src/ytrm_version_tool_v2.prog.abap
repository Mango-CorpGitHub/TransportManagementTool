*&---------------------------------------------------------------------*
*& Report YAAG_VERSION_TOOL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ytrm_version_tool_v2.

INCLUDE ytrm_version_tool_v2_top.
INCLUDE ytrm_version_tool_v2_clas.

DATA lv_trkorr TYPE e070-trkorr.
DATA lr_user   TYPE lcl_sh_for_transport_request=>ty_r_users.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT (28) FOR FIELD s_trkorr.
    SELECT-OPTIONS: s_trkorr FOR lv_trkorr NO INTERVALS.
    SELECTION-SCREEN POSITION 64.
    SELECTION-SCREEN PUSHBUTTON (8) f_ses USER-COMMAND f_ses.
    SELECTION-SCREEN POSITION 74.
    SELECTION-SCREEN PUSHBUTTON (4) see_tr USER-COMMAND see_tr.
  SELECTION-SCREEN END OF LINE.
  PARAMETERS p_descr TYPE e07t-as4text.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT (31) FOR FIELD p_owner.
    PARAMETERS p_owner TYPE sy-uname.
    PARAMETERS p_name TYPE user_addr-name_textc.
  SELECTION-SCREEN END OF LINE.
  PARAMETERS p_usr TYPE abap_bool AS CHECKBOX USER-COMMAND frad1 DEFAULT abap_true.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
  PARAMETERS p_comp TYPE abap_bool AS CHECKBOX USER-COMMAND frad1 DEFAULT abap_true.
  PARAMETERS rb_q   RADIOBUTTON GROUP rad USER-COMMAND frad1 DEFAULT 'X'.
  PARAMETERS rb_p   RADIOBUTTON GROUP rad.
SELECTION-SCREEN END OF BLOCK b2.

INCLUDE ytrm_version_tool_v2_sc.

INITIALIZATION.
  lcl_selection_screen=>initialization( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_trkorr-low.
  lcl_selection_screen=>on_value_request_for_s_trkorr( ).

AT SELECTION-SCREEN OUTPUT.
  lcl_selection_screen=>at_selection_screen_output( ).

AT SELECTION-SCREEN.
  lcl_selection_screen=>at_selection_screen( ).

START-OF-SELECTION.
  lcl_selection_screen=>start_of_selection( ).
