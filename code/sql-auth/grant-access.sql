-- Add a user, specifying the name in AD. When a user is added, it gets login access.
CREATE USER [logicapps-vro] FROM external provider
-- grant access to that user to execute stored proc
 grant execute on object::GetProducts to [logicapps-vro] 