CLASS ycl_trm_tr_object DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES yif_trm_tr_object .

    METHODS constructor
      IMPORTING
        !im_code           TYPE trkorr
        !im_position       TYPE ddposition
        !im_o_log          TYPE REF TO yif_trm_logger
        !im_o_db_interface TYPE REF TO yif_trm_transport_request_db
      RAISING
        ycx_trm_transport_request .
    CLASS-METHODS navigate
      IMPORTING
        !iv_pgmid       TYPE e071-pgmid
        !iv_object      TYPE e071-object
        !iv_object_name TYPE e071-obj_name
      RAISING
        ycx_trm_transport_request .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA: ai_o_transport_request TYPE REF TO yif_trm_transport_request,
          ai_code                TYPE trkorr,
          ai_position            TYPE ddposition,
          ai_s_entry_data        TYPE yc_transportrequestobject,
          ai_o_log               TYPE REF TO yif_trm_logger,
          ai_o_db_interface      TYPE REF TO yif_trm_transport_request_db.

    METHODS: get_entry_data RETURNING VALUE(re_s_data) TYPE yc_transportrequestobject.
ENDCLASS.



CLASS ycl_trm_tr_object IMPLEMENTATION.


  METHOD constructor.

    ai_code = im_code.

    ai_position = im_position.

    ai_o_transport_request = ycl_trm_transport_request=>get_by_code( im_code = ai_code ).

    ai_o_log          = im_o_log.
    ai_o_db_interface = im_o_db_interface.

    ai_s_entry_data = get_entry_data(  ).

    IF ai_s_entry_data IS INITIAL.
*      RAISE EXCEPTION delivery_document_exception( ycx_all_delivery_document=>item_not_exists ).
    ENDIF.

  ENDMETHOD.


  METHOD get_entry_data.

    DATA(lt_item_data) = ai_o_db_interface->fetch_entries( ai_o_transport_request ).

    TRY.
        re_s_data = lt_item_data[ KEY sorted_key transportrequestposition = ai_position ].
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

  ENDMETHOD.


  METHOD navigate.

    DATA(lo_log) = ycl_trm_logger=>new( ).

    CALL FUNCTION 'TR_OBJECT_JUMP_TO_TOOL'
      EXPORTING
        iv_pgmid          = iv_pgmid
        iv_object         = iv_object
        iv_obj_name       = iv_object_name
*       iv_action         = 'SHOW'
*       iv_client         =
      EXCEPTIONS
        jump_not_possible = 1
        OTHERS            = 2.
    IF sy-subrc <> 0.
      lo_log->add_from_system_variables( ).
      RAISE EXCEPTION NEW ycx_trm_transport_request( logger = lo_log ).
    ENDIF.

  ENDMETHOD.


  METHOD yif_trm_tr_object~get_activity.
    re_activity = ai_s_entry_data-activity.
  ENDMETHOD.


  METHOD yif_trm_tr_object~get_custo_entries.

    DATA(lt_custo_entries) = ai_o_db_interface->fetch_custo_entries( im_o_transport_request = ai_o_transport_request ).

    re_t_custo_entry = VALUE #( FOR custo_entry IN lt_custo_entries
                                USING KEY sorted_key_obj WHERE (
                                        objectid   = yif_trm_tr_object~get_object_id( )   AND
                                        mastertype = yif_trm_tr_object~get_object_type( ) AND
                                        mastername = yif_trm_tr_object~get_object_name( )
                                      )

                                ( NEW ycl_trm_tr_custo_entry(
                                  im_code           = ai_code
                                  im_object_id      = custo_entry-objectid
                                  im_object_type    = custo_entry-objecttype
                                  im_object_name    = custo_entry-objectname
                                  im_position       = custo_entry-transportrequestposition
                                  im_o_log          = ai_o_log
                                  im_o_db_interface = ai_o_db_interface
                                    )
                                 )
                               ).


  ENDMETHOD.


  METHOD yif_trm_tr_object~get_function.
    re_function = ai_s_entry_data-objectfunction.
  ENDMETHOD.


  METHOD yif_trm_tr_object~get_language.
    re_language = ai_s_entry_data-language.
  ENDMETHOD.


  METHOD yif_trm_tr_object~get_object_id.
    re_object_id = ai_s_entry_data-objectid.
  ENDMETHOD.

  METHOD yif_trm_tr_object~get_object_name.
    re_object_name = ai_s_entry_data-objectname.
  ENDMETHOD.


  METHOD yif_trm_tr_object~get_object_type.
    re_object_type = ai_s_entry_data-objecttype.
  ENDMETHOD.


  METHOD yif_trm_tr_object~get_transport_request.
    re_o_transport_request = ai_o_transport_request.
  ENDMETHOD.


  METHOD yif_trm_tr_object~has_collisions.
    TRY.
        DATA(lt_transport_request) = ycl_trm_transport_request=>get_by_attributes(
           EXPORTING
             im_s_query_by_attr     = VALUE #(
                                               transportrequestid = VALUE #( ( sign = 'I' option = 'NE' low = ai_o_transport_request->get_code(  ) ) )
                                               status             = VALUE #(
                                                                             ( sign = 'I' option = 'NE' low = yif_trm_transport_request=>status-release )
                                                                             ( sign = 'I' option = 'NE' low = yif_trm_transport_request=>status-release_with_import_protection )
                                                                           )
                                               entries_attr      = VALUE #(
                                                                             objecttype = VALUE #( ( sign = 'I' option = 'EQ' low = yif_trm_tr_object~get_object_type(  ) ) )
                                                                             objectname = VALUE #( ( sign = 'I' option = 'EQ' low = yif_trm_tr_object~get_object_name( ) ) )
                                                                          )
                                             )
         ).

        IF lt_transport_request IS NOT INITIAL.
          re_has_collisions = abap_true.
          ex_t_collisions = lt_transport_request.
        ENDIF.

      CATCH ycx_trm_transport_request.

    ENDTRY.
  ENDMETHOD.


  METHOD yif_trm_tr_object~is_customizing.

    re_is_custo = COND #( WHEN yif_trm_tr_object~get_function(  ) EQ yif_trm_tr_object=>function-customizing
                          THEN abap_true
                          ELSE abap_false
                        ).

  ENDMETHOD.


  METHOD yif_trm_tr_object~is_deleted.

    re_is_deleted = COND #( WHEN yif_trm_tr_object~get_function(  ) EQ yif_trm_tr_object=>function-deleted
                            THEN abap_true
                            ELSE abap_false
                          ).

  ENDMETHOD.
ENDCLASS.
