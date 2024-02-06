INTERFACE yif_trm_tr_custo_entry
  PUBLIC .


  TYPES:
    tab TYPE STANDARD TABLE OF REF TO yif_trm_tr_custo_entry WITH DEFAULT KEY .

  METHODS get_transport_request
    RETURNING
      VALUE(re_o_transport_request) TYPE REF TO yif_trm_transport_request .
  METHODS get_object_id
    RETURNING
      VALUE(re_object_id) TYPE yc_transportrequestobjectcusto-objectid .
  METHODS get_object_type
    RETURNING
      VALUE(re_object_type) TYPE yc_transportrequestobjectcusto-objecttype .
  METHODS get_object_name
    RETURNING
      VALUE(re_object_name) TYPE yc_transportrequestobjectcusto-objectname .
  METHODS get_position
    RETURNING
      VALUE(re_position) TYPE yc_transportrequestobjectcusto-transportrequestposition .
  METHODS get_master_type
    RETURNING
      VALUE(re_master_type) TYPE yc_transportrequestobjectcusto-mastertype .
  METHODS get_master_name
    RETURNING
      VALUE(re_master_name) TYPE yc_transportrequestobjectcusto-mastername .
  METHODS get_view_name
    RETURNING
      VALUE(re_view_name) TYPE yc_transportrequestobjectcusto-viewname .
  METHODS get_tab_key
    RETURNING
      VALUE(re_tab_key) TYPE yc_transportrequestobjectcusto-tabkey .
  METHODS get_sort_flag
    RETURNING
      VALUE(re_sort_flag) TYPE yc_transportrequestobjectcusto-sortflag .
  METHODS get_flag
    RETURNING
      VALUE(re_flag) TYPE yc_transportrequestobjectcusto-flag .
  METHODS get_language
    RETURNING
      VALUE(re_language) TYPE yc_transportrequestobjectcusto-language .
  METHODS get_activity
    RETURNING
      VALUE(re_activity) TYPE yc_transportrequestobjectcusto-activity .
ENDINTERFACE.
