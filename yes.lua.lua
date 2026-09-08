local Fluent = (function()
    -- ============================================================
    -- WRAPPER UNTUK MENYESUAIKAN KIMSGUI DENGAN SINTAKS FLUENT
    -- ============================================================

    -- Asumsikan Library sudah didefinisikan sebelumnya
    local Library = _G.Library or Library
    assert(Library, "Library KimsGUI tidak ditemukan! Pastikan didefinisikan sebelum wrapper.")

    -- Buat fungsi notifikasi yang kompatibel
    local function Notify(config)
        config = config or {}
        local title = config.Title or "Notifikasi"
        local content = config.Content or ""
        local duration = config.Duration or 3
        -- Icon diabaikan karena KimsGUI tidak mendukung icon di notif
        Library:MakeNotify({
            Title = title,
            Description = content,
            Delay = duration
        })
    end

    -- Objek window
    local function createWindow(config)
        config = config or {}
        local win = Library:Window({
            Title = config.Title or "Kims",
            Subtitle = config.SubTitle or "",
            -- Ukuran bisa disesuaikan dari config.Size jika ada
        })

        local windowObj = {
            _win = win,
            _tabs = {},
            _tabOrder = 0,

            AddTab = function(self, tabConfig)
                tabConfig = tabConfig or {}
                local tabName = tabConfig.Name or "Tab"
                local tabIcon = tabConfig.Icon or ""
                self._tabOrder = self._tabOrder + 1
                local tab = self._win:AddTab({
                    Name = tabName,
                    Icon = tabIcon
                })
                -- Bungkus tab untuk menyediakan AddSection dengan fleksibilitas
                local tabObj = {
                    _tab = tab,
                    _sections = {},
                    AddSection = function(self, sectionTitle, isOpen)
                        -- Fluent bisa dipanggil dengan string atau tabel
                        local title = sectionTitle
                        local open = isOpen
                        if type(sectionTitle) == "table" then
                            title = sectionTitle.Title or "Section"
                            open = sectionTitle.Open
                        end
                        local section = self._tab:AddSection(title, open)
                        local sectionObj = {
                            _section = section,
                            _components = {},
                            AddToggle = function(self, toggleConfig)
                                local result = section:AddToggle({
                                    Title = toggleConfig.Title or "Toggle",
                                    Default = toggleConfig.Default or false,
                                    Callback = toggleConfig.Callback,
                                    NoSave = toggleConfig.NoSave or false,
                                })
                                table.insert(self._components, result)
                                return result
                            end,
                            AddDropdown = function(self, dropdownConfig)
                                local values = dropdownConfig.Values or {}
                                local default = dropdownConfig.Default
                                -- Fluent menggunakan Multi untuk multi select
                                local multi = dropdownConfig.Multi or false
                                -- Untuk multi, default bisa berupa array
                                local result = section:AddDropdown({
                                    Title = dropdownConfig.Title or "Dropdown",
                                    Options = values,
                                    Default = default,
                                    Callback = dropdownConfig.Callback,
                                    Multi = multi,
                                    NoSave = dropdownConfig.NoSave or false,
                                })
                                table.insert(self._components, result)
                                return result
                            end,
                            AddInput = function(self, inputConfig)
                                local result = section:AddInput({
                                    Title = inputConfig.Title or "Input",
                                    Default = inputConfig.Default or "",
                                    Placeholder = inputConfig.Placeholder or "",
                                    Callback = inputConfig.Callback,
                                    NoSave = inputConfig.NoSave or false,
                                })
                                table.insert(self._components, result)
                                return result
                            end,
                            AddButton = function(self, buttonConfig)
                                local result = section:AddButton({
                                    Title = buttonConfig.Title or "Button",
                                    Callback = buttonConfig.Callback,
                                })
                                table.insert(self._components, result)
                                return result
                            end,
                            AddParagraph = function(self, paragraphConfig)
                                local title = paragraphConfig.Title or ""
                                local content = paragraphConfig.Content or ""
                                local richText = paragraphConfig.RichText
                                if richText == nil then richText = true end
                                local result = section:AddParagraph({
                                    Title = title,
                                    Content = content,
                                    RichText = richText,
                                })
                                table.insert(self._components, result)
                                return result
                            end,
                            AddSlider = function(self, sliderConfig)
                                -- Fluent slider diubah menjadi input dengan range
                                local title = sliderConfig.Title or "Slider"
                                local min = sliderConfig.Min or 0
                                local max = sliderConfig.Max or 100
                                local default = sliderConfig.Default or min
                                local callback = sliderConfig.Callback
                                local result = section:AddInput({
                                    Title = title .. " (" .. min .. " - " .. max .. ")",
                                    Default = tostring(default),
                                    Placeholder = "Nilai " .. min .. " - " .. max,
                                    Callback = function(val)
                                        local num = tonumber(val)
                                        if num and num >= min and num <= max then
                                            if callback then callback(num) end
                                        else
                                            -- Notifikasi nilai tidak valid
                                            Notify({ Title = "Slider", Content = "Nilai harus antara " .. min .. " dan " .. max, Duration = 2 })
                                        end
                                    end,
                                    NoSave = sliderConfig.NoSave or false,
                                })
                                table.insert(self._components, result)
                                return result
                            end,
                        }
                        table.insert(self._sections, sectionObj)
                        return sectionObj
                    end,
                }
                table.insert(self._tabs, tabObj)
                return tabObj
            end,

            SetMinimizeIcon = function(self, icon)
                -- Di KimsGUI, minimize icon sudah diatur dari awal, kita abaikan
                -- Bisa ditambahkan jika diperlukan
            end,
        }

        -- Simpan referensi untuk konfigurasi tambahan (MinimizeKey, dll) tidak digunakan
        return windowObj
    end

    -- Objek SaveManager dummy
    local SaveManager = {
        SetLibrary = function(self, lib) end,
        SetFolder = function(self, folder) end,
        BuildConfigSection = function(self, tab) end,
    }

    local InterfaceManager = {
        SetLibrary = function(self, lib) end,
        SetFolder = function(self, folder) end,
        BuildInterfaceSection = function(self, tab) end,
    }

    -- Objek Fluent utama
    local Fluent = {
        CreateWindow = function(self, config)
            return createWindow(config)
        end,
        Notify = function(self, config)
            Notify(config)
        end,
        SaveManager = SaveManager,
        InterfaceManager = InterfaceManager,
    }

    return Fluent
end)()