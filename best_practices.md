For the proper using of the tool and to ensure that the provided information is accurate, it is recommended to follow some best practices. 

Firstly, a programmer could have as many transport requests as they deem necessary; however, each transport request should be clearly identified. Ideally, the description should identify the project and ticket to which it refers, being as specific as possible.

Secondly, objects should be added to the corresponding transportation request for the development, regardless of whether they can be locked or not. 
It's known that if an object is locked in a transportation request, any user making modifications on it will add a new task to that request. Users not making changes for the project identified in the request should delete these tasks and manually add the objects to their own transportation requests.

Following those premises, it can be stated as follows: *A transportation request should reference a single development or project*. *All objects contained in that request will correspond to changes related to that development or project*.

Another best practice that facilitates code comparisons is to tag changes with an identifier for the referenced project, ticket, the user, and the date of the change. If a user uses the comparison mode of the tool, they could identify in each object which code blocks do not belong to them.
