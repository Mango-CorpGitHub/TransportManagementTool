@AbapCatalog.sqlViewName: 'YITRCUSTOKEY'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'CDS for Transport Request Customizing Keys'
define view YI_TRANSPORTREQUESTCUSTOKEY
     as select from e071k
{
    key trkorr      as TransportRequestId,
    key pgmid       as ObjectId,
    key object      as ObjectType, 
    key objname     as ObjectName ,  
    key as4pos      as TransportRequestCustoPosition,
        mastertype  as MasterType,
        mastername  as MasterName,
        viewname    as ViewName,
        objfunc     as ObjectFunction,
        tabkey      as TabKey,
        sortflag    as SortFlag,
        flag        as Flag,
        lang        as Language,
        activity    as Activity
}
