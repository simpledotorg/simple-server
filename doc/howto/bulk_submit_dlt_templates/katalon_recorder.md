[Katalon Recorder](https://chrome.google.com/webstore/detail/katalon-recorder-selenium/ljdobmomdgdljniojadhoplhkpialdid)

[Video walkthrough](https://drive.google.com/drive/folders/1kh-XSykRj6w5dGrjZh7sZXjSgvdAGtjU)

These are the commands to add in the test suite. You'll have to copy-paste these manually one at a time. 

| Command     | Target                                                         | Value        |
|-------------|----------------------------------------------------------------|--------------|
| loadVars    | <name of the Test Data file>                                   |              |
| open        | https://www.ucc-bsnl.co.in/new_content_templates/contentAdd/   |              |
| click       | xpath=//form[@id='contentAddForm']/div/div[2]/div/div[3]/label |              |
| click       | xpath=//input[@type='search']                                  |              |
| pause       |                                                                | 1000         |
| sendKeys    | xpath=//input[@type='search']                                  | ${KEY_ENTER} |
| click       | name=vcTemplateName                                            |              |
| type        | name=vcTemplateName                                            | ${name}      |
| click       | id=id_vcTemplateMessage                                        |              |
| type        | id=id_vcTemplateMessage                                        | ${message}   |
| click       | id=createtemp                                                  |              |
| endLoadVars |                                                                |              |
