All available permissions are listed in `app/policies/permissions.rb`. The file also describes a set of default access
roles. These permissions are used in Pundit policies to authorize access and scope models accessible by the user. Each
feature requires its own set of policies, for this we use Pundit's [namespaced policy
feature](https://github.com/varvet/pundit#policy-namespacing). We need to use the namespaceing because Pundit doesn't
allow us to pass more context to the policy finder.

(Note: Using a single policy per model would result in large conditional ladders in policies and
scopes, with a combinatorial increase in number of conditions based on the number of permissions
that effect the model)

### Adding a new permissions
- Add the permission slug to ALL_PERMISSIONS in permissions.rb. A new permission is keyed by its slug
  and is a hashmap that contains the following keys
    ```
    {
      slug: ...
      description: ...
      resource_priority: [...]
      required_permissions: [...]
    }
    ```
    - Slug is the identifier of the permission
    - Description is the string displayed to the user when creating new admins
    - resource_priority is the order in which a resource type is assigned to the user.
        - A permission can be assigned globally, for an organization, or for a facility group
        - The `resource_priorty` list is used find the appropriate resource_type from the list of selected resources
        - It creates a permission for all the available resources with the highest priority
    - required_permissions is list of other permissions a user must have before a permissions is assigned.
- Add this permission to appropriate ACCESS_LEVELS
- Update the policies for the features which are affected by this permission.
- There are a few helper methods to make defining permissions easier:
    - user_has_any_permissions?
        It takes varargs of the form [:permission_slug, resource] and check if user is authorized for any one of them
    - `resources_for_permission`
        Returns all the resources associated with a single permission
    - `organization_ids_for_permission`
        - If permission is assigned globally it returns all organization ids
        - If permission is assigned for orgnaizations, it returns their ids
        - If permission is assigned for facility group, it returns the ids of their organizations
    - `facility_group_ids_for_permission`
        - If permission is assigned globally it returns all faciliy_group ids
        - If permission is assigned for orgnaizations, it returns facility group ids for all their facility groups
        - If permission is assigned for facility group, it returns their ids.
    - `facility_ids_for_permission`
        - If permission is assigned globally it returns all faciliy ids
        - If permission is assigned for orgnaizations, it returns facility ids for all their facilities
        - If permission is assigned for facility group, it returns facility ids for all their faciliteis
