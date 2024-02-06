@AbapCatalog.sqlViewName: 'YCTRANSPREQOBJ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Objects from a Transport Request'
define view YC_TRANSPORTREQUESTOBJECT
  as select from YI_TRANSPORTREQUESTOBJECT
  
    association [1..1] to YC_TRANSPORTREQUEST as _TransportRequest on _TransportRequest.TransportRequestId = $projection.TransportRequestId
  
    association [0..*] to YC_TRANSPORTREQUESTOBJECTCUSTO as _ObjectCusto on  _ObjectCusto.TransportRequestId       = $projection.TransportRequestId
//                                                                         and _ObjectCusto.TransportRequestPosition = $projection.TransportRequestPosition
                                                                         and _ObjectCusto.ObjectId                 = $projection.ObjectId                                                             
                                                                         and _ObjectCusto.MasterType               = $projection.ObjectType
                                                                         and _ObjectCusto.MasterName               = $projection.ObjectName
{

  key TransportRequestId,
  key TransportRequestPosition,
      ObjectId,
      ObjectType,
      ObjectName,
      ObjectFunction,
      LockStatus,
      ObjectLanguageInformation,
      Language,
      Activity,
      _TransportRequest,
      _ObjectCusto
}
