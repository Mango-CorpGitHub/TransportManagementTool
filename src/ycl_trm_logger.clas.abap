
CLASS ycl_trm_logger DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    INTERFACES yif_trm_logger .

    ALIASES add_message
        FOR yif_trm_logger~add_message.
    ALIASES add_exception
       FOR yif_trm_logger~add_exception .
    ALIASES add_from_bapiret
      FOR yif_trm_logger~add_from_bapiret .
    ALIASES add_from_stmscalert
      FOR yif_trm_logger~add_from_stmscalert .
    ALIASES add_from_system_variables
      FOR yif_trm_logger~add_from_system_variables .
    ALIASES add_text
      FOR yif_trm_logger~add_text .
    ALIASES display
      FOR yif_trm_logger~display .
    ALIASES has_errors
      FOR yif_trm_logger~has_errors .
    ALIASES error
        for yif_trm_logger~error.
    ALIASES info
      FOR yif_trm_logger~info .
    ALIASES warning
      FOR yif_trm_logger~warning .
    ALIASES tab
      FOR yif_trm_logger~tab .

    METHODS constructor.

    CLASS-METHODS new
      RETURNING VALUE(ro_logger) TYPE REF TO yif_trm_logger.

  PRIVATE SECTION.

    DATA ai_handle TYPE balloghndl .
    DATA ai_s_header TYPE bal_s_log.


ENDCLASS.



CLASS ycl_trm_logger IMPLEMENTATION.


  METHOD yif_trm_logger~has_errors.

    DATA lt_msg_handles TYPE bal_t_msgh.
    CALL FUNCTION 'BAL_GLB_SEARCH_MSG'
      EXPORTING
        i_t_log_handle = VALUE bal_t_logh( ( ai_handle ) )
      IMPORTING
        e_t_msg_handle = lt_msg_handles
      EXCEPTIONS
        msg_not_found  = 1
        OTHERS         = 2.

    DATA ls_msg TYPE bal_s_msg.
    LOOP AT lt_msg_handles ASSIGNING FIELD-SYMBOL(<ls_msg_handles>).

      CALL FUNCTION 'BAL_LOG_MSG_READ'
        EXPORTING
          i_s_msg_handle = <ls_msg_handles>
        IMPORTING
          e_s_msg        = ls_msg.

      IF ls_msg-msgty = 'E'.
        rv_has_errors = abap_true.
        RETURN.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD yif_trm_logger~has_messages.

    DATA lt_msg_handles TYPE bal_t_msgh.
    CALL FUNCTION 'BAL_GLB_SEARCH_MSG'
      EXPORTING
        i_t_log_handle = VALUE bal_t_logh( ( ai_handle ) )
      IMPORTING
        e_t_msg_handle = lt_msg_handles
      EXCEPTIONS
        msg_not_found  = 1
        OTHERS         = 2.

    rv_has_messages = xsdbool( line_exists( lt_msg_handles[ 1 ] ) ).

  ENDMETHOD.


  METHOD constructor.

    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log      = ai_s_header
      IMPORTING
        e_log_handle = ai_handle
      EXCEPTIONS
        OTHERS       = 1.

  ENDMETHOD.


  METHOD yif_trm_logger~add_text.

    IF im_text IS INITIAL.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAL_LOG_MSG_ADD_FREE_TEXT'
      EXPORTING
        i_log_handle = ai_handle
        i_msgty      = im_type
        i_text       = CONV text255( im_text ).

  ENDMETHOD.


  METHOD yif_trm_logger~add_exception.

    IF im_o_exception IS NOT BOUND.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAL_LOG_EXCEPTION_ADD'
      EXPORTING
        i_log_handle = ai_handle
        i_s_exc      = VALUE bal_s_exc( msgty     = im_type
                                        exception = im_o_exception ).

  ENDMETHOD.


  METHOD yif_trm_logger~add_message.

    DATA(ls_message) = im_s_message.

    IF ls_message-msgid IS INITIAL.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_log_handle = ai_handle
        i_s_msg      = ls_message.

  ENDMETHOD.


  METHOD yif_trm_logger~add_from_system_variables.

    add_message( im_s_message = VALUE #( msgid     = sy-msgid
                                         msgty     = sy-msgty
                                         msgno     = sy-msgno
                                         msgv1     = sy-msgv1
                                         msgv2     = sy-msgv2
                                         msgv3     = sy-msgv3
                                         msgv4     = sy-msgv4 ) ).

  ENDMETHOD.


  METHOD yif_trm_logger~add_from_bapiret.

    LOOP AT im_t_bapiret ASSIGNING FIELD-SYMBOL(<ls_bapiret>).

      add_message( im_s_message = VALUE #( msgid     = <ls_bapiret>-id
                                           msgty     = <ls_bapiret>-type
                                           msgno     = <ls_bapiret>-number
                                           msgv1     = <ls_bapiret>-message_v1
                                           msgv2     = <ls_bapiret>-message_v2
                                           msgv3     = <ls_bapiret>-message_v3
                                           msgv4     = <ls_bapiret>-message_v4 ) ).

    ENDLOOP.

  ENDMETHOD.


  METHOD new.
    ro_logger = NEW ycl_trm_logger( ).
  ENDMETHOD.


  METHOD yif_trm_logger~add_from_stmscalert.

    DATA(ls_message) = CORRESPONDING bal_s_msg( im_s_stmscalert ).
    add_message( ls_message ).

  ENDMETHOD.


  METHOD yif_trm_logger~display.

    DATA ls_display_profile  TYPE bal_s_prof.
    CALL FUNCTION 'BAL_DSP_PROFILE_POPUP_GET'
      IMPORTING
        e_s_display_profile = ls_display_profile
      EXCEPTIONS
        OTHERS              = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    ls_display_profile-use_grid = abap_true.

    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING
        i_s_display_profile  = ls_display_profile
        i_t_log_handle       = VALUE bal_t_logh( ( ai_handle ) )
      EXCEPTIONS
        profile_inconsistent = 1
        internal_error       = 2
        no_data_available    = 3
        no_authority         = 4
        OTHERS               = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL FUNCTION 'BAL_LOG_MSG_DELETE_ALL'
      EXPORTING
        i_log_handle  = ai_handle
      EXCEPTIONS
        log_not_found = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.


  METHOD yif_trm_logger~info.
    add_text( im_text = im_text
              im_type = 'I' ).
  ENDMETHOD.


  METHOD yif_trm_logger~warning.
    add_text( im_text = im_text
              im_type = 'W' ).
  ENDMETHOD.

  method yif_trm_logger~error.
    add_text( im_text = im_text
              im_type = 'E'
            ).
  endmethod.
ENDCLASS.
