INTERFACE yif_trm_transport_request_db
  PUBLIC .


  TYPES:
    BEGIN OF typ_s_code,
      code TYPE trkorr,
    END OF typ_s_code .
  TYPES:
    typ_t_code TYPE STANDARD TABLE OF typ_s_code WITH KEY primary_key COMPONENTS code
                                                      WITH UNIQUE SORTED KEY sorted_key COMPONENTS code .
  TYPES:
    BEGIN OF typ_s_exists.
      INCLUDE TYPE typ_s_code.
  TYPES: exists TYPE abap_bool,
    END OF typ_s_exists .
  TYPES:
    typ_t_exists TYPE STANDARD TABLE OF typ_s_exists WITH KEY primary_key COMPONENTS code
                                                     WITH UNIQUE SORTED KEY sorted_key COMPONENTS code .
  TYPES:
    BEGIN OF typ_s_data.
      INCLUDE TYPE typ_s_code.
  TYPES: data TYPE yc_transportrequest,
    END OF typ_s_data .
  TYPES:
    typ_t_data TYPE STANDARD TABLE OF typ_s_data WITH KEY primary_key COMPONENTS code
                                                 WITH UNIQUE SORTED KEY sorted_key COMPONENTS code .
  TYPES:
    typ_t_entry TYPE STANDARD TABLE OF yc_transportrequestobject WITH KEY transportrequestposition
                                                                 WITH UNIQUE SORTED KEY sorted_key COMPONENTS transportrequestposition
                                                                 WITH NON-UNIQUE SORTED KEY sorted_key_obj COMPONENTS  objectid objecttype objectname .
  TYPES:
    BEGIN OF typ_s_entries.
      INCLUDE TYPE typ_s_code.
  TYPES: entries TYPE typ_t_entry,
    END OF typ_s_entries .
  TYPES:
    typ_t_entries TYPE STANDARD TABLE OF typ_s_entries WITH KEY primary_key COMPONENTS code
                                                       WITH UNIQUE SORTED KEY sorted_key COMPONENTS code .
  TYPES:
    typ_t_custo_entry TYPE STANDARD TABLE OF yc_transportrequestobjectcusto
                                                                            WITH DEFAULT KEY
*                                                                            WITH UNIQUE SORTED KEY sorted_key COMPONENTS transportrequestposition
                                                                            WITH UNIQUE SORTED KEY sorted_key COMPONENTS objectid objecttype objectname transportrequestposition
                                                                            WITH NON-UNIQUE SORTED KEY sorted_key_obj COMPONENTS objectid mastertype mastername .
  TYPES:
    BEGIN OF typ_s_custo_entries.
      INCLUDE TYPE typ_s_code.
  TYPES: entries TYPE typ_t_custo_entry,
    END OF typ_s_custo_entries .
  TYPES:
    typ_t_custo_entries TYPE STANDARD TABLE OF typ_s_custo_entries WITH KEY primary_key COMPONENTS code
                                                                   WITH UNIQUE SORTED KEY sorted_key COMPONENTS code .
  TYPES:
    typ_t_text TYPE STANDARD TABLE OF yc_transportrequesttext WITH KEY transportrequestid
                                                                          WITH UNIQUE SORTED KEY sorted_key COMPONENTS transportrequestid .
  TYPES:
    BEGIN OF typ_s_text.
      INCLUDE TYPE typ_s_code.
  TYPES: text TYPE typ_t_text,
    END OF typ_s_text .
  TYPES:
    typ_t_texts TYPE STANDARD TABLE OF typ_s_text WITH KEY primary_key COMPONENTS code
                                                                WITH UNIQUE SORTED KEY sorted_key COMPONENTS code .
  TYPES:
    BEGIN OF ty_s_customizing,
      rfc_to_quality                TYPE rfcdest,
      rfc_to_productive             TYPE rfcdest,
      request_target_system_quality TYPE tr_target,
      request_target_system_dev     TYPE tr_target,
    END OF ty_s_customizing .
  TYPES:
    BEGIN OF typ_s_load_cache_params,
      basic          TYPE abap_bool,
*            description        TYPE abap_bool,
      tasks          TYPE abap_bool,
      fetch_all_data TYPE abap_bool,
    END OF typ_s_load_cache_params .
  TYPES:
    typ_r_transportrequestid TYPE RANGE OF yc_transportrequest-transportrequestid .
  TYPES:
    typ_r_parent             TYPE RANGE OF yc_transportrequest-transportrequestparentid .
  TYPES:
    typ_r_type               TYPE RANGE OF yc_transportrequest-transportrequesttype .
  TYPES:
    typ_r_status             TYPE RANGE OF yc_transportrequest-transportrequeststatus .
  TYPES:
    typ_r_owner              TYPE RANGE OF yc_transportrequest-transportrequestowner .
  TYPES:
    typ_r_lastchangedate     TYPE RANGE OF yc_transportrequest-lastchangedate .
  TYPES:
    typ_r_lastchangetime     TYPE RANGE OF yc_transportrequest-lastchangetime .
  TYPES:
    typ_r_category           TYPE RANGE OF yc_transportrequest-transportrequestcategory .
  TYPES:
    typ_r_objectname         TYPE RANGE OF yc_transportrequestobject-objectname .
  TYPES:
    typ_r_objecttype         TYPE RANGE OF yc_transportrequestobject-objecttype .
  TYPES:
    typ_r_objectid           TYPE RANGE OF yc_transportrequestobject-objectid .
  TYPES:
    typ_r_lockstatus         TYPE RANGE OF yc_transportrequestobject-lockstatus .
  TYPES:
    typ_r_description        TYPE RANGE OF yc_transportrequesttext-description .
  TYPES:
    BEGIN OF typ_s_tr_entries_qry_by_attr,
      objectid   TYPE typ_r_objectid,
      objecttype TYPE typ_r_objecttype,
      objectname TYPE typ_r_objectname,
      lockstatus TYPE typ_r_lockstatus,
    END OF typ_s_tr_entries_qry_by_attr .
  TYPES:
    BEGIN OF typ_s_tr_query_by_attr,
      code               TYPE typ_t_code,
      transportrequestid TYPE typ_r_transportrequestid,
      type               TYPE typ_r_type,
      status             TYPE typ_r_status,
      category           TYPE typ_r_category,
      owner              TYPE typ_r_owner,
      lastchangedate     TYPE typ_r_lastchangedate,
      lastchangetime     TYPE typ_r_lastchangetime,
      parentid           TYPE typ_r_parent,
      entries_attr       TYPE typ_s_tr_entries_qry_by_attr,
    END OF typ_s_tr_query_by_attr .
  TYPES:
    BEGIN OF typ_s_tr_query_by_description,
      description TYPE typ_r_description,
    END OF typ_s_tr_query_by_description .

  CONSTANTS:
    BEGIN OF c_customizing,
      rfc_to_quality_name         TYPE tvarvc-name VALUE 'ZTRM_RFC_QUALITY',
      rfc_to_productive_name      TYPE tvarvc-name VALUE 'ZTRM_RFC_PRODUCTIVE',
      request_target_quality_name TYPE tvarvc-name VALUE 'ZTRM_REQUEST_TARGET_QUALITY',
      request_target_dev_name     TYPE tvarvc-name VALUE 'ZTRM_REQUEST_TARGET_DEV',
    END OF c_customizing .

  METHODS query_tr_data_by_attr
    IMPORTING
      !im_s_tr_query_by_attr TYPE yif_trm_transport_request_db=>typ_s_tr_query_by_attr
    RETURNING
      VALUE(re_t_code)       TYPE typ_t_code .
  METHODS query_tr_by_description
    IMPORTING
      !im_s_tr_query_by_description TYPE yif_trm_transport_request_db=>typ_s_tr_query_by_description
    RETURNING
      VALUE(re_t_code)              TYPE typ_t_code .
  METHODS check_exists
    IMPORTING
      !im_o_transport_request TYPE REF TO yif_trm_transport_request
    RETURNING
      VALUE(re_exists)        TYPE abap_bool .
  METHODS check_exists_list
    IMPORTING
      !im_t_transport_request TYPE typ_t_code
    RETURNING
      VALUE(re_t_exists)      TYPE typ_t_exists .
  METHODS fetch_data
    IMPORTING
      !im_o_transport_request TYPE REF TO yif_trm_transport_request
    RETURNING
      VALUE(re_s_data)        TYPE typ_s_data-data .
  METHODS fetch_data_list
    IMPORTING
      !im_t_transport_request TYPE typ_t_code
    RETURNING
      VALUE(re_t_data)        TYPE typ_t_data .
  METHODS fetch_entries
    IMPORTING
      !im_o_transport_request TYPE REF TO yif_trm_transport_request
    RETURNING
      VALUE(re_t_entries)     TYPE typ_s_entries-entries .
  METHODS fetch_entries_list
    IMPORTING
      !im_t_transport_request TYPE typ_t_code
    RETURNING
      VALUE(re_t_entries)     TYPE typ_t_entries .
  METHODS fetch_custo_entries
    IMPORTING
      !im_o_transport_request   TYPE REF TO yif_trm_transport_request
    RETURNING
      VALUE(re_t_custo_entries) TYPE typ_s_custo_entries-entries .
  METHODS fetch_custo_entries_list
    IMPORTING
      !im_t_transport_request   TYPE typ_t_code
    RETURNING
      VALUE(re_t_custo_entries) TYPE typ_t_custo_entries .
  METHODS fetch_text_list
    IMPORTING
      !im_t_transport_request TYPE typ_t_code
    RETURNING
      VALUE(re_t_text)        TYPE typ_t_texts .
  METHODS fetch_text
    IMPORTING
      !im_o_transport_request TYPE REF TO yif_trm_transport_request
    RETURNING
      VALUE(re_t_text)        TYPE typ_s_text-text .
  METHODS fetch_customizing
    RETURNING
      VALUE(rs_customizing) TYPE ty_s_customizing .
  METHODS load_cache
    IMPORTING
      !im_t_codes             TYPE yif_trm_transport_request_db=>typ_t_code OPTIONAL
      !im_s_load_cache_params TYPE yif_trm_transport_request_db=>typ_s_load_cache_params .
  METHODS clear_cache .
  METHODS set_ignore_cache
    IMPORTING
      !im_ignore_cache TYPE abap_bool .
ENDINTERFACE.
