CLASS ycl_trm_transport_request_db DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    INTERFACES yif_trm_transport_request_db .

    CLASS-METHODS create
      RETURNING
        VALUE(re_o_db) TYPE REF TO yif_trm_transport_request_db .
  PROTECTED SECTION.

  PRIVATE SECTION.

    CLASS-DATA as_o_db_interface TYPE REF TO yif_trm_transport_request_db.

    DATA:
      ai_ignore_cache          TYPE abap_bool,
      ai_t_exists_cache        TYPE yif_trm_transport_request_db~typ_t_exists,
      ai_t_data_cache          TYPE yif_trm_transport_request_db~typ_t_data,
      ai_t_entries_cache       TYPE yif_trm_transport_request_db~typ_t_entries,
      ai_t_custo_entries_cache TYPE yif_trm_transport_request_db~typ_t_custo_entries,
      ai_t_text_cache          TYPE yif_trm_transport_request_db~typ_t_texts,
      ai_s_customizing         TYPE yif_trm_transport_request_db~ty_s_customizing.

    METHODS fetch_exists_from_db IMPORTING im_t_transport_request TYPE yif_trm_transport_request_db~typ_t_code
                                 RETURNING VALUE(re_t_exists)     TYPE yif_trm_transport_request_db~typ_t_exists.

    METHODS fetch_exists_and_merge IMPORTING im_t_transport_request TYPE yif_trm_transport_request_db~typ_t_code
                                   RETURNING VALUE(re_t_exists)     TYPE yif_trm_transport_request_db~typ_t_exists.

    METHODS fetch_data_from_db IMPORTING im_t_transport_request TYPE yif_trm_transport_request_db~typ_t_code
                               RETURNING VALUE(re_t_data)       TYPE yif_trm_transport_request_db~typ_t_data.

    METHODS fetch_data_and_merge IMPORTING im_t_transport_request TYPE yif_trm_transport_request_db~typ_t_code
                                 RETURNING VALUE(re_t_data)       TYPE yif_trm_transport_request_db~typ_t_data.

    METHODS fetch_entries_from_db IMPORTING im_t_transport_request TYPE yif_trm_transport_request_db~typ_t_code
                                  RETURNING VALUE(re_t_entries)    TYPE yif_trm_transport_request_db~typ_t_entries.

    METHODS fetch_entries_and_merge IMPORTING im_t_transport_request TYPE yif_trm_transport_request_db~typ_t_code
                                    RETURNING VALUE(re_t_entries)    TYPE yif_trm_transport_request_db~typ_t_entries.

    METHODS fetch_custo_entries_from_db IMPORTING im_t_transport_request    TYPE yif_trm_transport_request_db~typ_t_code
                                        RETURNING VALUE(re_t_custo_entries) TYPE yif_trm_transport_request_db~typ_t_custo_entries.

    METHODS fetch_custo_entries_and_merge IMPORTING im_t_transport_request    TYPE yif_trm_transport_request_db~typ_t_code
                                          RETURNING VALUE(re_t_custo_entries) TYPE yif_trm_transport_request_db~typ_t_custo_entries.

    METHODS fetch_text_from_db IMPORTING im_t_transport_request TYPE yif_trm_transport_request_db~typ_t_code
                               RETURNING VALUE(re_t_text)       TYPE yif_trm_transport_request_db~typ_t_texts.
    METHODS fetch_text_and_merge IMPORTING im_t_transport_request TYPE yif_trm_transport_request_db~typ_t_code
                                 RETURNING VALUE(re_t_text)       TYPE yif_trm_transport_request_db~typ_t_texts.

ENDCLASS.



CLASS ycl_trm_transport_request_db IMPLEMENTATION.


  METHOD yif_trm_transport_request_db~set_ignore_cache.
    ai_ignore_cache = im_ignore_cache.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~query_tr_data_by_attr.

    IF im_s_tr_query_by_attr IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_query) = |tr~transportrequestid             IN @im_s_tr_query_by_attr-transportrequestid| &&
                     | AND tr~transportrequesttype      IN @im_s_tr_query_by_attr-type|               &&
                     | AND tr~transportrequestcategory  IN @im_s_tr_query_by_attr-category|           &&
                     | AND tr~transportrequestowner     IN @im_s_tr_query_by_attr-owner|              &&
                     | AND tr~transportrequeststatus    IN @im_s_tr_query_by_attr-status|             &&
                     | AND tr~lastchangedate            IN @im_s_tr_query_by_attr-lastchangedate|     &&
                     | AND tr~lastchangetime            IN @im_s_tr_query_by_attr-lastchangetime|     &&
                     | AND tr~transportrequestparentid  IN @im_s_tr_query_by_attr-parentid| .


    IF im_s_tr_query_by_attr-entries_attr IS INITIAL.

      IF im_s_tr_query_by_attr-code IS NOT INITIAL.
        SELECT tr~transportrequestid
          FROM yc_transportrequest AS tr
           FOR ALL ENTRIES IN @im_s_tr_query_by_attr-code
         WHERE tr~transportrequestid EQ @im_s_tr_query_by_attr-code-code
           AND (lv_query)
          INTO TABLE @DATA(lt_code).
      ELSE.
        SELECT tr~transportrequestid
          FROM yc_transportrequest AS tr
         WHERE (lv_query)
         INTO TABLE @lt_code.
      ENDIF.

    ELSE.
      lv_query = lv_query &&
                 | AND trobj~objectid   IN @im_s_tr_query_by_attr-entries_attr-objectid|     &&
                 | AND trobj~ObjectType IN @im_s_tr_query_by_attr-entries_attr-ObjectType|   &&
                 | AND trobj~ObjectName IN @im_s_tr_query_by_attr-entries_attr-ObjectName|   &&
                 | AND trobj~LockStatus IN @im_s_tr_query_by_attr-entries_attr-LockStatus|.


      IF im_s_tr_query_by_attr-code IS NOT INITIAL.
        SELECT tr~transportrequestid
          FROM yc_transportrequest AS tr
         INNER JOIN yc_transportrequestobject AS trobj
            ON tr~transportrequestid EQ trobj~transportrequestid
           FOR ALL ENTRIES IN @im_s_tr_query_by_attr-code
         WHERE tr~transportrequestid EQ @im_s_tr_query_by_attr-code-code
           AND (lv_query)
          INTO TABLE @DATA(lt_code_obj).
      ELSE.
        SELECT tr~transportrequestid
          FROM yc_transportrequest AS tr
         INNER JOIN yc_transportrequestobject AS trobj
            ON tr~transportrequestid EQ trobj~transportrequestid
         WHERE (lv_query)
          INTO TABLE @lt_code_obj.



      ENDIF.
*      lt_code = CORRESPONDING #( lt_code_obj DISCARDING DUPLICATES MAPPING transportrequestid = transportrequestid ).

      lt_code =  CORRESPONDING #( lt_code_obj ).
      SORT lt_code BY transportrequestid.
      DELETE ADJACENT DUPLICATES FROM lt_code COMPARING transportrequestid.

    ENDIF.

    re_t_code = VALUE #( FOR <data> IN lt_code ( code = <data>-transportrequestid ) ).


  ENDMETHOD.


  METHOD yif_trm_transport_request_db~query_tr_by_description.

    SELECT text~transportrequestid
      FROM yc_transportrequesttext AS text
     WHERE description IN @im_s_tr_query_by_description-description
     INTO TABLE @DATA(lt_code).

    SORT lt_code BY transportrequestid.
    DELETE ADJACENT DUPLICATES FROM lt_code COMPARING transportrequestid.
    re_t_code = lt_code.

  ENDMETHOD.


  METHOD yif_trm_transport_request_db~load_cache.
    yif_trm_transport_request_db~check_exists_list( im_t_codes ).

    "delivery document cache
    DATA(lt_transport_request) = yif_trm_transport_request_db~fetch_data_list( im_t_codes ).

    yif_trm_transport_request_db~fetch_entries_list( im_t_codes ).
    yif_trm_transport_request_db~fetch_custo_entries_list( im_t_codes ).
    yif_trm_transport_request_db~fetch_text_list( im_t_codes ).

    IF im_s_load_cache_params-fetch_all_data EQ abap_true OR im_s_load_cache_params-tasks EQ abap_true.
      DATA(lt_task) = yif_trm_transport_request_db~query_tr_data_by_attr( im_s_tr_query_by_attr = VALUE #( parentid = VALUE #( FOR code IN im_t_codes ( sign = 'I' option = 'EQ' low = code ) ) ) ).
      IF lt_task IS NOT INITIAL.
        yif_trm_transport_request_db~load_cache( EXPORTING im_t_codes = lt_task
                                                           im_s_load_cache_params = im_s_load_cache_params ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_text_list.
    IF ai_ignore_cache = abap_true.
      re_t_text = fetch_text_from_db( im_t_transport_request ).
    ELSE.
      re_t_text = fetch_text_and_merge( im_t_transport_request ).
    ENDIF.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_text.
    DATA(lt_text) = yif_trm_transport_request_db~fetch_text_list( VALUE #( ( code = im_o_transport_request->get_code( ) ) ) ).

    TRY.
        re_t_text = lt_text[ 1 ]-text.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_entries_list.
    IF ai_ignore_cache = abap_true.
      re_t_entries = fetch_entries_from_db( im_t_transport_request ).
    ELSE.
      re_t_entries = fetch_entries_and_merge( im_t_transport_request ).
    ENDIF.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_entries.
    DATA(lt_data) = yif_trm_transport_request_db~fetch_entries_list( VALUE #( ( code = im_o_transport_request->get_code( ) ) ) ).

    TRY.
        re_t_entries = lt_data[ 1 ]-entries.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_data_list.
    IF ai_ignore_cache = abap_true.
      re_t_data = fetch_data_from_db( im_t_transport_request ).
    ELSE.
      re_t_data = fetch_data_and_merge( im_t_transport_request ).
    ENDIF.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_data.
    DATA(lt_data) = yif_trm_transport_request_db~fetch_data_list( VALUE #( ( code = im_o_transport_request->get_code( ) ) ) ).

    TRY.
        re_s_data = lt_data[ 1 ]-data.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_custo_entries_list.
    IF ai_ignore_cache = abap_true.
      re_t_custo_entries = fetch_custo_entries_from_db( im_t_transport_request ).
    ELSE.
      re_t_custo_entries = fetch_custo_entries_and_merge( im_t_transport_request ).
    ENDIF.

  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_custo_entries.
    DATA(lt_data) = yif_trm_transport_request_db~fetch_custo_entries_list( VALUE #( ( code = im_o_transport_request->get_code( ) ) ) ).

    TRY.
        re_t_custo_entries = lt_data[ 1 ]-entries.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~fetch_customizing.

    rs_customizing = ai_s_customizing.
    IF rs_customizing IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA lt_r_name TYPE RANGE OF tvarvc-name.
    lt_r_name = VALUE #( ( sign = 'I' option = 'EQ' low = yif_trm_transport_request_db=>c_customizing-rfc_to_quality_name )
                         ( sign = 'I' option = 'EQ' low = yif_trm_transport_request_db=>c_customizing-rfc_to_productive_name )
                         ( sign = 'I' option = 'EQ' low = yif_trm_transport_request_db=>c_customizing-request_target_quality_name )
                         ( sign = 'I' option = 'EQ' low = yif_trm_transport_request_db=>c_customizing-request_target_dev_name )
                       ).

    SELECT name, low FROM tvarvc
        WHERE name IN @lt_r_name
        INTO TABLE @DATA(lt_customizing).
    IF NOT line_exists( lt_customizing[ 1 ] ).
      RETURN.
    ENDIF.

    ai_s_customizing-rfc_to_quality = VALUE #( lt_customizing[ name = yif_trm_transport_request_db=>c_customizing-rfc_to_quality_name ]-low OPTIONAL ).
    ai_s_customizing-rfc_to_productive = VALUE #( lt_customizing[ name = yif_trm_transport_request_db=>c_customizing-rfc_to_productive_name ]-low OPTIONAL ).
    ai_s_customizing-request_target_system_quality = VALUE #( lt_customizing[ name = yif_trm_transport_request_db=>c_customizing-request_target_quality_name ]-low OPTIONAL ).
    ai_s_customizing-request_target_system_dev = VALUE #( lt_customizing[ name = yif_trm_transport_request_db=>c_customizing-request_target_dev_name ]-low OPTIONAL ).

    rs_customizing = ai_s_customizing.

  ENDMETHOD.


  METHOD yif_trm_transport_request_db~clear_cache.
    REFRESH:
             ai_t_exists_cache,
             ai_t_data_cache,
             ai_t_entries_cache,
             ai_t_custo_entries_cache,
             ai_t_text_cache.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~check_exists_list.
    IF ai_ignore_cache = abap_true.
      re_t_exists = fetch_exists_from_db( im_t_transport_request ).
    ELSE.
      re_t_exists = fetch_exists_and_merge( im_t_transport_request ).
    ENDIF.
  ENDMETHOD.


  METHOD yif_trm_transport_request_db~check_exists.
    DATA(lt_exists) = yif_trm_transport_request_db~check_exists_list( VALUE #( ( code = im_o_transport_request->get_code( ) ) ) ).
    re_exists = lt_exists[ 1 ]-exists.
  ENDMETHOD.


  METHOD fetch_text_from_db.
    IF im_t_transport_request IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_texts TYPE STANDARD TABLE OF yc_transportrequesttext WITH DEFAULT KEY
                                                                 WITH NON-UNIQUE SORTED KEY sorted_key COMPONENTS transportrequestid.

    SELECT trtext~*
      FROM yc_transportrequesttext AS trtext
       FOR ALL ENTRIES IN @im_t_transport_request
     WHERE trtext~transportrequestid = @im_t_transport_request-code
      INTO TABLE @lt_texts.

    re_t_text = VALUE #( FOR <tr> IN im_t_transport_request ( code  = <tr>-code
                                                              text = FILTER #( lt_texts USING KEY sorted_key WHERE transportrequestid = <tr>-code
                                                                             )
                                                            )
                         ).

  ENDMETHOD.


  METHOD fetch_text_and_merge.
    DATA: lt_cached_data TYPE yif_trm_transport_request_db~typ_t_texts.

    IF lines( im_t_transport_request ) EQ 1.
      DATA(lv_code) = im_t_transport_request[ 1 ]-code.
      TRY.
          DATA(ls_cached_data) = ai_t_text_cache[ KEY sorted_key code = lv_code ].
          APPEND ls_cached_data TO re_t_text.
          RETURN.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
    ELSE.
      lt_cached_data = FILTER #( ai_t_text_cache IN im_t_transport_request USING KEY sorted_key WHERE code = code ).
    ENDIF.

    DATA(lt_missing_codes) = FILTER #( im_t_transport_request EXCEPT IN lt_cached_data USING KEY sorted_key WHERE code = code ).

    IF lt_missing_codes IS NOT INITIAL.
      DATA(lt_fetched_data) = fetch_text_from_db( lt_missing_codes ).
    ENDIF.

    re_t_text = lt_cached_data.
    APPEND LINES OF lt_fetched_data TO: re_t_text,
                                        ai_t_text_cache.
  ENDMETHOD.


  METHOD fetch_exists_from_db.
    IF im_t_transport_request IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_palau TYPE yif_trm_transport_request_db~typ_t_code.

    SELECT tr~transportrequestid AS code
      FROM yc_transportrequest AS tr
       FOR ALL ENTRIES IN @im_t_transport_request
     WHERE tr~transportrequestid EQ @im_t_transport_request-code
      INTO TABLE @lt_palau.

    re_t_exists = VALUE #( FOR <tr> IN im_t_transport_request ( code   = <tr>-code
                                                                exists = COND #( WHEN line_exists( lt_palau[ KEY sorted_key code = <tr>-code ] )
                                                                                THEN abap_true
                                                                                ELSE abap_false
                                                                               )
                                                              )
                         ).


  ENDMETHOD.


  METHOD fetch_exists_and_merge.
    DATA: lt_cached_exists TYPE yif_trm_transport_request_db~typ_t_exists.

    IF lines( im_t_transport_request ) EQ 1.
      DATA(lv_code) = im_t_transport_request[ 1 ]-code.
      TRY.
          DATA(ls_cached_exists) = ai_t_exists_cache[ KEY sorted_key code = lv_code ].
          APPEND ls_cached_exists TO re_t_exists.
          RETURN.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
    ELSE.
      lt_cached_exists = FILTER #( ai_t_exists_cache IN im_t_transport_request USING KEY sorted_key WHERE code = code ).
    ENDIF.

    DATA(lt_missing_codes) = FILTER #( im_t_transport_request EXCEPT IN lt_cached_exists USING KEY sorted_key WHERE code = code ).

    IF lt_missing_codes IS NOT INITIAL.
      DATA(lt_fetched_exists) = fetch_exists_from_db( lt_missing_codes ).
    ENDIF.

    re_t_exists = lt_cached_exists.
    APPEND LINES OF lt_fetched_exists TO: re_t_exists,
                                          ai_t_exists_cache.
  ENDMETHOD.


  METHOD fetch_entries_from_db.
    IF im_t_transport_request IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_hangar TYPE STANDARD TABLE OF yc_transportrequestobject WITH DEFAULT KEY
                                                                     WITH NON-UNIQUE SORTED KEY sorted_key COMPONENTS transportrequestid.

    SELECT trentries~*
      FROM yc_transportrequestobject AS trentries
       FOR ALL ENTRIES IN @im_t_transport_request
     WHERE trentries~transportrequestid = @im_t_transport_request-code
      INTO TABLE @lt_hangar.

    re_t_entries = VALUE #( FOR <tr> IN im_t_transport_request ( code    = <tr>-code
                                                                 entries = FILTER #( lt_hangar USING KEY sorted_key WHERE transportrequestid = <tr>-code ) ) ).
  ENDMETHOD.


  METHOD fetch_entries_and_merge.
    DATA: lt_cached_entries TYPE yif_trm_transport_request_db~typ_t_entries.

    IF lines( im_t_transport_request ) = 1.

      DATA(lv_code) = im_t_transport_request[ 1 ]-code.
      ASSIGN ai_t_entries_cache[ KEY sorted_key code = lv_code ] TO FIELD-SYMBOL(<entries_cache>).
      IF sy-subrc IS INITIAL.
        APPEND <entries_cache> TO lt_cached_entries.
      ENDIF.

    ELSE.

      lt_cached_entries = FILTER #( ai_t_entries_cache IN im_t_transport_request USING KEY sorted_key WHERE code = code ).

    ENDIF.

    DATA(lt_missing_codes) = FILTER #( im_t_transport_request EXCEPT IN lt_cached_entries USING KEY sorted_key WHERE code = code ).

    DATA(lt_fetched_entries) = fetch_entries_from_db( lt_missing_codes ).

    re_t_entries = lt_cached_entries.
    APPEND LINES OF lt_fetched_entries TO: re_t_entries,
                                           ai_t_entries_cache.
  ENDMETHOD.


  METHOD fetch_data_from_db.
    IF im_t_transport_request IS INITIAL.
      RETURN.
    ENDIF.

    SELECT tr~*
      FROM yc_transportrequest     AS tr
       FOR ALL ENTRIES IN @im_t_transport_request
     WHERE tr~transportrequestid = @im_t_transport_request-code
      INTO TABLE @DATA(lt_data).

    re_t_data = VALUE #( FOR <data> IN lt_data ( code = <data>-transportrequestid
                                                 data = <data> ) ).
  ENDMETHOD.


  METHOD fetch_data_and_merge.
    DATA: lt_cached_data TYPE yif_trm_transport_request_db~typ_t_data.

    IF lines( im_t_transport_request ) EQ 1.
      DATA(lv_code) = im_t_transport_request[ 1 ]-code.
      TRY.
          DATA(ls_cached_data) = ai_t_data_cache[ KEY sorted_key code = lv_code ].
          APPEND ls_cached_data TO re_t_data.
          RETURN.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
    ELSE.
      lt_cached_data = FILTER #( ai_t_data_cache IN im_t_transport_request USING KEY sorted_key WHERE code = code ).
    ENDIF.

    DATA(lt_missing_codes) = FILTER #( im_t_transport_request EXCEPT IN lt_cached_data USING KEY sorted_key WHERE code = code ).

    IF lt_missing_codes IS NOT INITIAL.
      DATA(lt_fetched_data) = fetch_data_from_db( lt_missing_codes ).
    ENDIF.

    re_t_data = lt_cached_data.
    APPEND LINES OF lt_fetched_data TO: re_t_data,
                                        ai_t_data_cache.
  ENDMETHOD.


  METHOD fetch_custo_entries_from_db.
    IF im_t_transport_request IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_llica TYPE STANDARD TABLE OF yc_transportrequestobjectcusto WITH DEFAULT KEY
                                                                          WITH NON-UNIQUE SORTED KEY sorted_key COMPONENTS transportrequestid.

    SELECT trcustoentries~*
      FROM yc_transportrequestobjectcusto AS trcustoentries
       FOR ALL ENTRIES IN @im_t_transport_request
     WHERE trcustoentries~transportrequestid = @im_t_transport_request-code
      INTO TABLE @lt_llica.

    re_t_custo_entries = VALUE #( FOR <tr> IN im_t_transport_request ( code    = <tr>-code
                                                                       entries = FILTER #( lt_llica USING KEY sorted_key WHERE transportrequestid = <tr>-code ) ) ).
  ENDMETHOD.


  METHOD fetch_custo_entries_and_merge.
    DATA: lt_cached_entries TYPE yif_trm_transport_request_db~typ_t_custo_entries.

    IF lines( im_t_transport_request ) = 1.

      DATA(lv_code) = im_t_transport_request[ 1 ]-code.
      ASSIGN ai_t_custo_entries_cache[ KEY sorted_key code = lv_code ] TO FIELD-SYMBOL(<entries_cache>).
      IF sy-subrc IS INITIAL.
        APPEND <entries_cache> TO lt_cached_entries.
      ENDIF.

    ELSE.

      lt_cached_entries = FILTER #( ai_t_custo_entries_cache IN im_t_transport_request USING KEY sorted_key WHERE code = code ).

    ENDIF.

    DATA(lt_missing_codes) = FILTER #( im_t_transport_request EXCEPT IN lt_cached_entries USING KEY sorted_key WHERE code = code ).

    DATA(lt_fetched_entries) = fetch_custo_entries_from_db( lt_missing_codes ).

    re_t_custo_entries = lt_cached_entries.
    APPEND LINES OF lt_fetched_entries TO: re_t_custo_entries,
                                           ai_t_custo_entries_cache.
  ENDMETHOD.


  METHOD create.

    IF as_o_db_interface IS NOT BOUND.
      as_o_db_interface = NEW ycl_trm_transport_request_db( ).
    ENDIF.

    re_o_db = as_o_db_interface.

  ENDMETHOD.
ENDCLASS.
