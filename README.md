
## Description
In ABAP development teams, it's common for programmers to collaborate on the same objects simultaneously. When preparing a transport between environments, particular attention is required for objects containing code contributed by multiple developers, ensuring that only approved changes are included for deployment. This tool is designed to streamline and centralize tasks associated with transport requests, such as creating transport copies, comparing objects across environments, collectively releasing request blocks, and more. When confronted with complex tasks, it enables programmers to make well-informed decisions based on the most accurate information.

Made by ABAPers for ABAPers.

## Installation
Install this project via [ABAPGit](https://abapgit.org/). 

## Configuration
Configure the following variables in transaction `STVARV`:
- **YTRM_REQUEST_TARGET_QUALITY**: System Identifier and Client for the Quality system in format "SYS.CLI".
- **YTRM_RFC_PRODUCTIVE**: Trusted RFC name against the Production system with current user logon.
- **YTRM_RFC_QUALITY**: Trusted RFC name against the Quality system with current user logon.
  An example of RFC configuration:
  
## Usage
Learn full potential of this tool with a real example in our [Usage Guide](usage.md).

## Best Practices
Follow the provided [methodology](best_practices.md) to achieve optimal tool performance and maintain a coordinated team in all matters related to the transport of objects.

## License
Terms & Conditions set out in the [LICENSE file](LICENSE).

## Contribution

## Change History
