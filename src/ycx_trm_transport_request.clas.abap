CLASS ycx_trm_transport_request DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_t100_dyn_msg .
    INTERFACES if_t100_message .

    DATA: msgty TYPE symsgty.

    CONSTANTS:
      BEGIN OF not_exists,
        msgid TYPE symsgid VALUE yif_trm_transport_request=>message_class,
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'CODE',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF not_exists .
    CONSTANTS:
      BEGIN OF is_locked,
        msgid TYPE symsgid VALUE yif_trm_transport_request=>message_class,
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'CODE',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF is_locked .
    DATA code TYPE trkorr .
    DATA customizing_name TYPE tvarvc-name .
    CONSTANTS:
      BEGIN OF customizing_missing_in_stvarvc,
        msgid TYPE symsgid VALUE yif_trm_transport_request=>message_class,
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'CUSTOMIZING_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF customizing_missing_in_stvarvc.

     CONSTANTS:
      BEGIN OF entry_not_deleted,
        msgid TYPE symsgid VALUE yif_trm_transport_request=>message_class,
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'CODE',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF entry_not_deleted .

    METHODS constructor
      IMPORTING
        !textid           LIKE if_t100_message=>t100key OPTIONAL
        !previous         LIKE previous OPTIONAL
        !code             TYPE trkorr OPTIONAL
        !customizing_name TYPE tvarvc-name OPTIONAL
        !logger           TYPE REF TO yif_trm_logger OPTIONAL
        !msgty            TYPE symsgty OPTIONAL .

    DATA: logger TYPE REF TO yif_trm_logger.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycx_trm_transport_request IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    me->code = code .
    me->customizing_name = customizing_name .
    me->logger = logger .
    me->msgty = msgty .
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
