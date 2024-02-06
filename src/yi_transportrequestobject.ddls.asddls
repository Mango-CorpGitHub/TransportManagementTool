@AbapCatalog.sqlViewName: 'YITRANSPREQOBJ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Objects from a Transport Request'
define view YI_TRANSPORTREQUESTOBJECT
  as select from e071
{

  key trkorr   as TransportRequestId,
  key as4pos   as TransportRequestPosition,
      pgmid    as ObjectId,
      object   as ObjectType,
      obj_name as ObjectName,
      objfunc  as ObjectFunction,
      lockflag as LockStatus,
      gennum   as ObjectLanguageInformation,
      lang     as Language,
      activity as Activity
}
