@AbapCatalog.sqlViewName: 'YITRANSPORTREQ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'CDS Transport Request'
define view YI_TRANSPORTREQUEST

  as select from e070
{
  key trkorr     as TransportRequestId,
  trfunction as TransportRequestType,
  trstatus   as TransportRequestStatus,
  tarsystem  as TransportRequestTarget,
  korrdev    as TransportRequestCategory,
  as4user    as TransportRequestOwner,
  as4date    as LastChangeDate,
  as4time    as LastChangeTime,
  strkorr    as TransportRequestParentId
}
