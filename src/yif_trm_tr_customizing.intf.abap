INTERFACE yif_trm_tr_customizing
  PUBLIC .


  INTERFACES yif_trm_transport_request .

  ALIASES get_category
    FOR yif_trm_transport_request~get_category .
  ALIASES get_code
    FOR yif_trm_transport_request~get_code .
  ALIASES get_description
    FOR yif_trm_transport_request~get_description .
  ALIASES get_owner
    FOR yif_trm_transport_request~get_owner .
  ALIASES get_status
    FOR yif_trm_transport_request~get_status .
  ALIASES get_type
    FOR yif_trm_transport_request~get_type .

ENDINTERFACE.
