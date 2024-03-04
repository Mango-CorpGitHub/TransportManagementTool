# Usage Guide
**Developer A** is working on a development and stores the changes, both for existing objects and new ones, in a transport request. **Developer B** is working in parallel on another development and also needs to make some changes to objects common to **Developer A**. To do this, **Developer B** creates their own transport request and enters the necessary entries for their changes.

**Developer A** needs to initially upload the changes from their development to the Quality system, with the purpose of verifying proper functionality with more test cases.
For doing that **Developer A** excutes this Transport Management Tool. Selection screen will be as following:

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/33a67701-0dd2-4be6-bc9d-b521c5293858)


It can be noted that the program operates in two modes, depending on the target system (Quality or Production) against which the transport is to be carried out. The information is presented in the same format in both modes; however, the options are adapted to the specific needs of the programmer in each mode. The check-box *"Compare Objects"* complements the information to be displayed.

**Developer A** should enter their transport request(s) in the select-option *"Request/Task"* and mark the Quality destination. To fully utilize the tool's functionality, ensure that the "Compare objects" checkbox is also selected.  If the "Only my request" box is checked, the tool will verify if there is a Transport Request/Task among those entered that is not owned by the user executing the program, which is useful for error checking. Once executed, a screen similar to the following will be displayed:

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/1777978a-2956-416d-b759-d019099dca0f)


At a first glance, two ALVs can be seen, each one will show its own information.

The upper ALV (TR Objects) displays a list of all objects included in the requests entered on the selection screen. If the *"Compare Objects"* flag is selected, the subcomponents of each object will be shown. For instance, if the request contains the entry R3TR CLAS, it will be broken down into its private, public, protected parts, methods, and local classes. The display will also indicate whether each component is new or has changes compared to the target system, as denoted by the *It is new* and *It is equal* columns.

It is recommended to use the tool with the *"Compare Objects"* flag checked, even though the comparison between systems may slow down the display of results. However, as previously mentioned, this enables users to fully leverage the tool's capabilities. If the flag is not checked, the list of request objects will still be displayed but without the breakdown of subcomponents and without identifying any changes compared to the destination system.

The column that links each object to the lower part's ALV is the *Collision* column. The **Collision** concept identifies whether an object is present in more than one transport request. This serves as a warning that an object may have changes from another programmer and may require discarding those changes before transporting it to another environment. An object/subobject will be identified as having collisions with the Red icon in the *"Has Collisions"* column. If the icon in the column is green, it indicates that it has no collisions.

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/e9857145-6477-4f00-91b2-beeb146c28a1)

The objects in the ALV will be sorted to display those with collisions first, as they require special attention.

The lower ALV (Collisions) will correspond to the list of transport requests that have collisions with the objects from the transport entered on the selection screen.

Both ALVs are related through the toolbar. The idea is that if the user selects an object from the list, the Collisions ALV will be filtered to display only the requests with conflicts related to that specific component. In the same way, if the user selects a request from the collisions list, the ALV of objects will be filtered to display only those components that are present in that order. 
Returning to the previously described use case, imagine a third developer(**Developer C**) that has included new changes related to another development. This generates a new collision.

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/b299e23c-e3fb-43f4-8f59-36d450ac2b27)

**Developer A** wants to know how many collisions has an specific object. For doing this, **Developer A** select that individual object in TR Object ALV and push button "Show object collisions"

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/81ad1e9c-8733-4aa9-9179-f76699c5bd5d)

**Developer A** also wants to know for collision, how many objects are afected by that. For doing this, **Developer A** select an individual transport request in Collisions ALV and push button "Show TR collisions"

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/ee914428-2a2c-4c01-b07f-6f6da73d1636)

The "Show all collisions" buttons will allow returning to the initial state and clearing any filtering.

It can be observed that **Developer A** has two objects colliding with other transport requests. **Developer A** will have to decide whether to include those changes from **Developer B** and **Developer C** in their transport to the Quality environment. For doing that, TR Object ALV has a *Compare Object* button for checking individual components with changes against destination system. Once **Developer A** has decided which changes to upload to Quality to test their development, the tool provides the capability to generate a Transport of Copy for this specific purpose. In Quality mode *"Create Transport of Copies"* button is available for that purpose. This button automatically creates a Transport of Copies request, released if the user wishes, with objects containing changes compared to Quality. By default, this tool will only include all new and modified components. However, it is also possible to manually select which objects from the ALV to include or exclude in the Transport of Copies request. This is possible thanks to the *"Add to ToC"* column. When  **Developer A** has decided which objects will be included and push the button, a popup like this will be shown:

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/3693da7a-e9e4-4c09-b4ef-15a30817e475)

A proposed name is included, along with the option to release the ToC request automatically and to open the STMS directly for its import into the destination system.

**Developer A** will repeat this procedure as many times as needed to thoroughly test the functionality that have developed and receive confirmation that the changes are correct and should be taken to production. **Developer A** is aware of changes from **Developer B** (collisions) but does not require those other changes to be confirmed before transporting their own. **Developer A** will only move to Production the changes related to their specific development. In this step, **Developer A** is ready for executing the tool, entering their transport requests and changing the Destination mode on the selection screen radio-button.

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/e54b15ff-76d2-4f10-bd02-8641f3591bdd)


In this mode, the information will be displayed in the same format explained earlier, continuing to show the componentes by object and conflicts with other developments. The main difference is that the tool will compare the objects against the production system, allowing identification of what has changed and what is new. It will be the user's task to decide which changes will be taken to the production environment, and the tool will provide all the information needed to make that decision. All functionalities previously described are present in this mode, except (logically) the button to create a Transport of Copies request, in its place, a "Release" button appears.

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/7d5eddd1-dec2-4be9-a6aa-c1ccaeb223ca)

It is again advisable for **Developer A** to review the conflicts, identify which code should not be transported, and ensure the transport before releasing. Visually, there is a *"Reviewed"* column in ALV to provide an indicator of which objects have been checked. Once **Developer A** has removed the code that should not be included and is confident in their decision, *"Release"* button could be pushed. with this button, all the transport request entered on the selection screen will be released simultaneously and ready to be imported into the subsequent systems.

