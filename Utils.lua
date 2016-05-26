local ADDON_NAME, VARREN_DEV_TOOLS = ...;

function VARREN_DEV_TOOLS:DEBUG(self, text)
    if self.debug then
        print(text);
    end
end