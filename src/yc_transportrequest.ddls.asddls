@AbapCatalog.sqlViewName: 'YCTRANSPORTREQ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Transport Request'
define view YC_TRANSPORTREQUEST

  as select from YI_TRANSPORTREQUEST

  association [0..*] to YC_TRANSPORTREQUEST       as _Task                   on _Task.TransportRequestParentId = $projection.TransportRequestId
  association [0..*] to YC_TRANSPORTREQUESTOBJECT as _TransportRequestObject on _TransportRequestObject.TransportRequestId = $projection.TransportRequestId
  association [0..*] to YC_TRANSPORTREQUESTTEXT   as _Description            on _Description.TransportRequestId = $projection.TransportRequestId

{

  key TransportRequestId,
      TransportRequestType,
      TransportRequestStatus,
      TransportRequestTarget,
      TransportRequestCategory,
      TransportRequestOwner,
      LastChangeDate,
      LastChangeTime,
      TransportRequestParentId,

      _Task,
      _TransportRequestObject,
      _Description

}
