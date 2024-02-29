INTERFACE yif_trm_logger
  PUBLIC .

  CONSTANTS:
    BEGIN OF msgty,
      info    TYPE symsgty VALUE 'I',
      success TYPE symsgty VALUE 'S',
      warning TYPE symsgty VALUE 'W',
      error   TYPE symsgty VALUE 'E',
      cancel  TYPE symsgty VALUE 'A',
      none    TYPE symsgty VALUE '-',
    END OF msgty.

  TYPES:
    tab TYPE STANDARD TABLE OF REF TO yif_trm_logger WITH DEFAULT KEY .

  METHODS add_text IMPORTING im_text TYPE csequence
                             im_type TYPE symsgty.

  METHODS add_exception IMPORTING im_o_exception TYPE REF TO cx_root
                                  im_type        TYPE symsgty.

  METHODS add_message IMPORTING im_s_message  TYPE bal_s_msg.

  METHODS add_from_bapiret IMPORTING im_t_bapiret TYPE bapiret2_t.

  METHODS add_from_stmscalert IMPORTING im_s_stmscalert TYPE stmscalert.

  METHODS add_from_ctsgerrmsg IMPORTING im_t_ctsgerrmsgs TYPE ctsgerrmsgs.

  METHODS add_from_system_variables.

  METHODS has_errors
    RETURNING VALUE(rv_has_errors) TYPE abap_bool.

  METHODS has_messages
    RETURNING VALUE(rv_has_messages) TYPE abap_bool.

  METHODS display.

  METHODS info IMPORTING im_text TYPE csequence.

  METHODS error IMPORTING im_text TYPE csequence.

  METHODS warning IMPORTING im_text TYPE csequence.

ENDINTERFACE.
