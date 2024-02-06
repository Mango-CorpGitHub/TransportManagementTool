INTERFACE yif_trm_tr_object
  PUBLIC .


  TYPES:
    tab TYPE STANDARD TABLE OF REF TO yif_trm_tr_object WITH DEFAULT KEY .

  CONSTANTS:
    BEGIN OF function,
      userdefined TYPE objfunc VALUE 'C',
      customizing TYPE objfunc VALUE 'K',
      deleted     TYPE objfunc VALUE 'D',
    END OF function .

  METHODS get_transport_request
    RETURNING
      VALUE(re_o_transport_request) TYPE REF TO yif_trm_transport_request .

  METHODS get_object_id
    RETURNING
      VALUE(re_object_id) TYPE yc_transportrequestobject-objectid .
  METHODS get_object_type
    RETURNING
      VALUE(re_object_type) TYPE yc_transportrequestobject-objecttype .
  METHODS get_object_name
    RETURNING
      VALUE(re_object_name) TYPE yc_transportrequestobject-objectname .
  METHODS get_function
    RETURNING
      VALUE(re_function) TYPE yc_transportrequestobject-objectfunction .
  "! La entrada de la orden tiene entrada de customizing
  "! @parameter re_is_custo | La entrada tiene entradas de customizing
  METHODS is_customizing
    RETURNING
      VALUE(re_is_custo) TYPE abap_bool .
  "! La entrada de la orden tiene el flag de borrado
  METHODS is_deleted
    RETURNING
      VALUE(re_is_deleted) TYPE abap_bool .
  "! Obtener las entradas de custo
  METHODS get_custo_entries
    RETURNING
      VALUE(re_t_custo_entry) TYPE yif_trm_tr_custo_entry=>tab .
  METHODS get_activity
    RETURNING
      VALUE(re_activity) TYPE yc_transportrequestobject-activity .
  METHODS get_language
    RETURNING
      VALUE(re_language) TYPE yc_transportrequestobject-language .
  METHODS has_collisions
    EXPORTING
      !ex_t_collisions         TYPE yif_trm_transport_request=>tab
    RETURNING
      VALUE(re_has_collisions) TYPE abap_bool .
ENDINTERFACE.
