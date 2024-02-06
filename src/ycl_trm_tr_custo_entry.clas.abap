CLASS ycl_trm_tr_custo_entry DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES yif_trm_tr_custo_entry .

    METHODS constructor
      IMPORTING
        !im_code           TYPE trkorr
        !im_object_id      TYPE pgmid
        !im_object_type    TYPE trobjtype
        !im_object_name    TYPE tabname
        !im_position       TYPE ddposition
        !im_o_log          TYPE REF TO yif_trm_logger
        !im_o_db_interface TYPE REF TO yif_trm_transport_request_db
      RAISING
        ycx_trm_transport_request .

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA: ai_o_transport_request TYPE REF TO yif_trm_transport_request,
          ai_code                TYPE trkorr,
          ai_object_id           TYPE pgmid,
          ai_object_type         TYPE trobjtype,
          ai_object_name         TYPE tabname,
          ai_position            TYPE ddposition,
          ai_s_entry_data        TYPE yc_transportrequestobjectcusto,
          ai_o_log               TYPE REF TO yif_trm_logger,
          ai_o_db_interface      TYPE REF TO yif_trm_transport_request_db.
    METHODS: get_entry_data RETURNING VALUE(re_s_data) TYPE yc_transportrequestobjectcusto.

ENDCLASS.



CLASS ycl_trm_tr_custo_entry IMPLEMENTATION.


  METHOD constructor.

    ai_o_db_interface = ycl_trm_transport_request_db=>create( ).

    ai_code        = im_code.
    ai_object_id   = im_object_id.
    ai_object_type = im_object_type.
    ai_object_name = im_object_name.
    ai_position    = im_position.
    ai_o_transport_request = ycl_trm_transport_request=>get_by_code( ai_code ).

    ai_s_entry_data = get_entry_data(  ).

  ENDMETHOD.

  METHOD get_entry_data.

    DATA(lt_item_data) = ai_o_db_interface->fetch_custo_entries( ai_o_transport_request ).

    TRY.
        re_s_data = lt_item_data[ KEY sorted_key objectid   = ai_object_id
                                                 objecttype = ai_object_type
                                                 objectname = ai_object_name
                                                 transportrequestposition = ai_position ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

  ENDMETHOD.

  METHOD yif_trm_tr_custo_entry~get_activity.
    re_activity = ai_s_entry_data-activity.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_flag.
    re_flag = ai_s_entry_data-flag.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_language.
    re_language = ai_s_entry_data-language.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_master_name.
    re_master_name = ai_s_entry_data-mastername.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_master_type.
    re_master_type = ai_s_entry_data-mastertype.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_object_id.
    re_object_id = ai_s_entry_data-objectid.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_object_name.
    re_object_name = ai_s_entry_data-objectname.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_object_type.
    re_object_type = ai_s_entry_data-objecttype.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_position.
    re_position = ai_s_entry_data-transportrequestposition.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_sort_flag.
    re_sort_flag = ai_s_entry_data-sortflag.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_tab_key.
    re_tab_key = ai_s_entry_data-tabkey.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_transport_request.
    re_o_transport_request = ai_o_transport_request.
  ENDMETHOD.


  METHOD yif_trm_tr_custo_entry~get_view_name.
    re_view_name = ai_s_entry_data-viewname.
  ENDMETHOD.
ENDCLASS.
