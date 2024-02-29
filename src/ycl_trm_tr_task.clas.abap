CLASS ycl_trm_tr_task DEFINITION
  PUBLIC
  INHERITING FROM ycl_trm_transport_request
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES yif_trm_tr_task .

    METHODS constructor
      IMPORTING
        !im_code            TYPE trkorr
        !im_o_parent_logger TYPE REF TO yif_trm_logger
      RAISING
        ycx_trm_transport_request .

    METHODS yif_trm_transport_request~release
        REDEFINITION .
  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_trm_tr_task IMPLEMENTATION.


  METHOD constructor.

    super->constructor(
      EXPORTING
        im_code = im_code
        im_o_logger = im_o_parent_logger
    ).

    IF get_db_interface(  )->fetch_data( me )-transportrequestparentid IS INITIAL.
      data(lx_tr) = NEW ycx_trm_transport_request( ).
      RAISE EXCEPTION lx_tr.
    ENDIF.
  ENDMETHOD.


  METHOD yif_trm_transport_request~release.

    IF yif_trm_transport_request~get_category(  ) EQ yif_trm_tr_task~type-unclassified.
      CALL FUNCTION 'TRINT_TDR_USER_COMMAND'
        EXPORTING
          iv_object  = ai_code
          iv_type    = 'TASK'
          iv_command = 'DELE'.

      ai_o_log->info( |Unclassified Task { ai_code } was deleted| ).

    ELSE.

      super->yif_trm_transport_request~release(  ).

    ENDIF.
  ENDMETHOD.


  METHOD yif_trm_tr_task~get_transport_request.
    re_transport_request = ycl_trm_transport_request=>get_by_code(
                             im_code            = get_db_interface(  )->fetch_data( me )-transportrequestparentid
*                             im_o_parent_logger =
                           ).
  ENDMETHOD.
ENDCLASS.
