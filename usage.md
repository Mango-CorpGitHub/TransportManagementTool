**Developer A** is working on a development and stores the changes, both for existing objects and new ones, in a transport request. **Developer B** is working in parallel on another development and also needs to make some changes to objects common to **Developer A**. To do this, **Developer B** creates their own transport request and enters the necessary entries for their changes.

**Developer A** needs to initially upload the changes from their development to the Quality system, with the purpose of verifying proper functionality with more test cases.
For doing that **Developer A** excutes this Transport Management Tool. Selection screen will be as following:

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/0011595c-3cae-45e9-a775-accd6111aec7)

It can be stated that the program has two modes, depending on the system (Quality or Production) against which the transport is to be carried out. The information is presented in the same format in both modes; however, the options are adapted to what the programmer may need in each mode. The check-box *"Compare Objects"* complements the information to be displayed.

**Developer A** should enter their transport request(s) in the select-option *"Request/Task"* and mark the Quality destination. To fully leverage the functionality of the tool, the *"Compare objects"* checkbox should also be checked. If *"Only my request"* box is checked, tool will verify if there is a Transport Request/Task among those entered whose owner is not the user who executes the program, useful for checking errors. Once executed, a screen similar to the following will be displayed:

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/590eaf0d-7073-4ef3-b9ef-3817ad6f672c)

At a first glance, two ALVs can be seen, each one will show its own information.

The upper ALV (TR Objects) corresponds to the list of all objects included in the requests entered in the selection screen. If the *"Compare Objects"* flag was selected, the subcomponents of each object will be displayed. That is, if the request has the entry R3TR CLAS, it will be shown broken down into its private, public, protected parts, methods, and local classes. It will also indicate if each component is new or has changes (*It is new* and *It is equal* columns) compared to the target system. 
It is recommended to use the tool with the *"Compare Objects"* flag checked, even though the comparison between systems may slow down the display of results. Nevertheless, as mentioned earlier, it will allow you to harness the full potential of the tool. 
If the flag is not checked, the list of request objects will still be displayed, but without breaking down by subcomponents and without identifying if there are changes compared to the destination system.

The column that links each object to the lower part's ALV is the *Collision* column. The **Collision** concept identifies if an object is present in more than one transport request. This allows warning that an object may have changes from another programmer and may need to discard those changes before transporting it to another environment. An object/subobject will be identified as having collisions with the Red icon in the *"Has Collisions"* column. If the icon in the column is green, it indicates that it has no collisions.

 ![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/7376437e-ff51-4715-aafa-712dc1f0ac80)

The objects in the ALV will be sorted to display those with collisions first, as they require special attention.

The lower ALV (Collisions) will correspond to the list of transport requests that have collisions with the objects from the transport entered on the selection screen.

Both ALVs are related through the toolbar. The idea is that if the user selects an object from the list, the Collisions ALV will be filtered to display only the requests with conflicts related to that specific component. In the same way, if the user selects a request from the collisions list, the ALV of objects will be filtered to display only those components that are present in that order. For doing this:

In TR Object ALV select an individual object and push button

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/e74908ac-0371-41f4-bc70-3f334a278896)

In Collisions ALV select an indiidual request and push button

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/2a6630dc-ca5e-4cdb-99a9-2e0c1682fd0e)

The "Show all collisions" buttons will allow returning to the initial state and clearing any filtering.

Returning to the previously described use case, it can be observed that **Developer A** has two methods colliding with another transport order. **Developer A** will have to decide whether to include those changes from **Developer B** in their transport to the Quality environment. For doing that, TR Object ALV has a *Compare Object* button for checking individual components with changes against destination system. Once **Developer A** has decided which changes to upload to Quality to test their development, the tool will allow them to create a copy order for this purpose. In Quality mode *"Create Transport of Copies"* button is available for that purpose. This button automatically creates a transport request (released if the user wishes) with objects containing changes compared to Quality. By default, this tool will only include all new and modified components. However, it is also possible to manually select which objects from the ALV to include or exclude in the Transport of Copies request. This is possible thanks to the *"Add to ToC"* column. When  **Developer A** has decided which objects will be included and push the button, a popup like this will be shown:

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/234de07f-1f45-4a29-af54-b4df4507a700)

A proposed name is included, along with the option to release the ToC request automatically and to open the STMS directly for its import into the destination system.

**Developer A** will repeat this procedure as many times as needed to thoroughly test the functionality that have developed and receive confirmation that the changes are correct and should be taken to production. **Developer A** is aware of changes from **Developer B** (collisions) but does not require those other changes to be confirmed before transporting their own. **Developer A** will only move to Production the changes related to their specific development. In this step, **Developer A** is ready for executing the tool, entering their transport requests and changing the Destination mode on the selection screen radio-button.

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/149a4f80-9b00-4128-9721-e3390b3e2955)


In this mode, the information will be displayed in the same format explained earlier, continuing to show the componentes by object and conflicts with other developments. The main difference is that the tool will compare the objects against the production system, allowing identification of what has changed and what is new. It will be the user's task to decide which changes will be taken to the production environment, and the tool will provide all the information needed to make that decision. All functionalities previously described are present in this mode, except (logically) the button to create a copy transport order, in its place, a "Release" button appears.

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/4aa4f033-80c5-450e-b5e5-4fda16cce82d)



Visually, the programmer can indicate what has been reviewed and what has not through the 'Reviewed' column.
Once the decision has been made on which changes will be uploaded to production, the 'Release' button can be used to release all the transport requests entered on the selection screen.
