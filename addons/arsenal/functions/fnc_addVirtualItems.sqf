#include "script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Alganthe, Dedmen
 * Add virtual items to the provided target.
 *
 * Arguments:
 * 0: Target <OBJECT>
 * 1: Items <ARRAY of strings> <BOOL>
 * 2: Add globally <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_box, ["item1", "item2", "itemN"]] call ace_arsenal_fnc_addVirtualItems
 * [_box, true, false] call ace_arsenal_fnc_addVirtualItems
 *
 * Public: Yes
*/

params [["_object", objNull, [objNull]], ["_items", [], [true, []]], ["_global", false, [false]]];

if (_object == objNull) exitWith {};
if (_items isEqualType [] && {count _items == 0}) exitWith {};

private _cargo = _object getVariable [QGVAR(virtualItems), [
    [[], [], []], // Weapons 0, primary, secondary, handgun
    [[], [], [], []], // WeaponAccessories 1, optic,side,muzzle,bipod
    [ ], // Magazines 2
    [ ], // Headgear 3
    [ ], // Uniform 4
    [ ], // Vest 5
    [ ], // Backpacks 6
    [ ], // Goggles 7
    [ ], // NVGs 8
    [ ], // Binoculars 9
    [ ], // Map 10
    [ ], // Compass 11
    [ ], // Radio slot 12
    [ ], // Watch slot  13
    [ ], // Comms slot 14
    [ ], // WeaponThrow 15
    [ ], // WeaponPut 16
    [ ] // InventoryItems 17
]];

private _configCfgWeapons = configFile >> "CfgWeapons"; //Save this lookup in variable for perf improvement

if (_items isEqualType true) then {
    if (_items) then {
        private _configItems = uiNamespace getVariable QGVAR(configItems);

        private _cargoWeapons = _cargo select IDX_VIRT_WEAPONS;
        private _configWeapons = _configItems select IDX_VIRT_WEAPONS;
        private _cargoAttachments = _cargo select IDX_VIRT_ATTACHMENTS;
        private _configAttachments = _configItems select IDX_VIRT_ATTACHMENTS;

        {
            (_x select 0) append (_x select 1);
            (_x select 2) set [(_x select 3), (_x select 0) arrayIntersect (_x select 0)];
        } forEach [
            [_cargoWeapons select 0, _configWeapons select 0, _cargoWeapons, 0],
            [_cargoWeapons select 1, _configWeapons select 1, _cargoWeapons, 1],
            [_cargoWeapons select 2, _configWeapons select 2, _cargoWeapons, 2],
            [_cargoAttachments select 0, _configAttachments select 0, _cargoAttachments, 0],
            [_cargoAttachments select 1, _configAttachments select 1, _cargoAttachments, 1],
            [_cargoAttachments select 2, _configAttachments select 2, _cargoAttachments, 2],
            [_cargoAttachments select 3, _configAttachments select 3, _cargoAttachments, 3]
        ];

        for "_index" from 2 to 17 do {
            (_cargo select _index) append (_configItems select _index);
            _cargo set [_index, (_cargo select _index) arrayIntersect (_cargo select _index)];
        };
    };

} else {
    {
        if (_x isEqualType "") then {
            private _configItemInfo = _configCfgWeapons >> _x >> "ItemInfo";
            private _simulationType = getText (_configCfgWeapons >> _x >> "simulation");
            switch true do {
                case (isClass (_configCfgWeapons >> _x)): {
                    switch true do {
                        /* Weapon acc */
                        case (
                                isClass (_configItemInfo) &&
                                {(getNumber (_configItemInfo >> "type")) in [TYPE_MUZZLE, TYPE_OPTICS, TYPE_FLASHLIGHT, TYPE_BIPOD]} &&
                                {!(_x isKindOf ["CBA_MiscItem", (_configCfgWeapons)])}
                            ): {
                            private _cargoAttachments = _cargo select IDX_VIRT_ATTACHMENTS;
                            switch (getNumber (_configItemInfo >> "type")) do {
                                case TYPE_OPTICS: {
                                    _cargoAttachments select 0 pushBackUnique _x;
                                };
                                case TYPE_FLASHLIGHT: {
                                    _cargoAttachments select 1 pushBackUnique _x;
                                };
                                case TYPE_MUZZLE: {
                                    _cargoAttachments select 2 pushBackUnique _x;
                                };
                                case TYPE_BIPOD: {
                                    _cargoAttachments select 3 pushBackUnique _x;
                                };
                            };
                        };
                        /* Headgear */
                        case (isClass (_configItemInfo) &&
                            {getNumber (_configItemInfo >> "type") == TYPE_HEADGEAR}): {
                            (_cargo select IDX_VIRT_HEADGEAR) pushBackUnique _x;
                        };
                        /* Uniform */
                        case (isClass (_configItemInfo) &&
                            {getNumber (_configItemInfo >> "type") == TYPE_UNIFORM}): {
                            (_cargo select IDX_VIRT_UNIFORM) pushBackUnique _x;
                        };
                        /* Vest */
                        case (isClass (_configItemInfo) &&
                            {getNumber (_configItemInfo >> "type") == TYPE_VEST}): {
                            (_cargo select IDX_VIRT_VEST) pushBackUnique _x;
                        };
                        /* NVgs */
                        case (_simulationType == "NVGoggles"): {
                            (_cargo select IDX_VIRT_HMDS) pushBackUnique _x;
                        };
                        /* Binos */
                        case (_simulationType == "Binocular" ||
                            {(_simulationType == 'Weapon') && {(getNumber (_configCfgWeapons >> _x >> 'type') == TYPE_BINOCULAR_AND_NVG)}}): {
                            (_cargo select IDX_VIRT_BINOS) pushBackUnique _x;
                        };
                        /* Map */
                        case (_simulationType == "ItemMap"): {
                            (_cargo select IDX_VIRT_MAP) pushBackUnique _x;
                        };
                        /* Compass */
                        case (_simulationType == "ItemCompass"): {
                            (_cargo select IDX_VIRT_COMPASS) pushBackUnique _x;
                        };
                        /* Radio */
                        case (_simulationType == "ItemRadio"): {
                            (_cargo select IDX_VIRT_RADIO) pushBackUnique _x;
                        };
                        /* Watch */
                        case (_simulationType == "ItemWatch"): {
                            (_cargo select IDX_VIRT_WATCH) pushBackUnique _x;
                        };
                        /* GPS */
                        case (_simulationType == "ItemGPS" ||
                            (isClass (_configItemInfo) && {getNumber (_configItemInfo >> "type") == TYPE_UAV_TERMINAL})): {
                            (_cargo select IDX_VIRT_GPS) pushBackUnique _x;
                        };
                        /* Weapon, at the bottom to avoid adding binos */
                        case (isClass (_configCfgWeapons >> _x >> "WeaponSlotsInfo") &&
                            {getNumber (_configCfgWeapons >> _x >> 'type') != TYPE_BINOCULAR_AND_NVG}): {
                            private _weaponsArray = _cargo select IDX_VIRT_WEAPONS;
                            private _baseWeapon = _x call bis_fnc_baseWeapon;

                            switch (getNumber (_configCfgWeapons >> _x >> "type")) do {
                                case TYPE_WEAPON_PRIMARY: {
                                    _weaponsArray select 0 pushBackUnique  _baseWeapon;
                                };
                                case TYPE_WEAPON_HANDGUN: {
                                    _weaponsArray select 2 pushBackUnique _baseWeapon;
                                };
                                case TYPE_WEAPON_SECONDARY: {
                                    _weaponsArray select 1 pushBackUnique _baseWeapon;
                                };
                            };
                        };
                        /* Misc items */
                        case (
                                isClass (_configItemInfo) &&
                                ((getNumber (_configItemInfo >> "type")) in [TYPE_MUZZLE, TYPE_OPTICS, TYPE_FLASHLIGHT, TYPE_BIPOD] &&
                                {(_x isKindOf ["CBA_MiscItem", (_configCfgWeapons)])}) ||
                                {(getNumber (_configItemInfo >> "type")) in [TYPE_FIRST_AID_KIT, TYPE_MEDIKIT, TYPE_TOOLKIT]} ||
                                {(getText (_configCfgWeapons >> _x >> "simulation")) == "ItemMineDetector"}
                            ): {
                            (_cargo select IDX_VIRT_MISCELLANEOUS) pushBackUnique _x;
                        };
                    };
                };
                case (isClass (configFile >> "CfgMagazines" >> _x)): {
                    // Lists to check against
                    private _grenadeList = [];
                    {
                        _grenadeList append getArray (_configCfgWeapons >> "Throw" >> _x >> "magazines");
                        false
                    } count getArray (_configCfgWeapons >> "Throw" >> "muzzles");

                    private _putList = [];
                    {
                        _putList append getArray (_configCfgWeapons >> "Put" >> _x >> "magazines");
                        false
                    } count getArray (_configCfgWeapons >> "Put" >> "muzzles");

                    // Check what the magazine actually is
                    switch true do {
                        // Rifle, handgun, secondary weapons mags
                        case (
                                ((getNumber (configFile >> "CfgMagazines" >> _x >> "type") in [TYPE_MAGAZINE_PRIMARY_AND_THROW,TYPE_MAGAZINE_SECONDARY_AND_PUT,1536,TYPE_MAGAZINE_HANDGUN_AND_GL]) ||
                                {(getNumber (configFile >> "CfgMagazines" >> _x >> QGVAR(hide))) == -1}) &&
                                {!(_x in _grenadeList)} &&
                                {!(_x in _putList)}
                            ): {
                            (_cargo select IDX_VIRT_MAGAZINES) pushBackUnique _x;
                        };
                        // Grenades
                        case (_x in _grenadeList): {
                            (_cargo select IDX_VIRT_GRENADE) pushBackUnique _x;
                        };
                        // Put
                        case (_x in _putList): {
                            (_cargo select IDX_VIRT_EXPLOSIVE) pushBackUnique _x;
                        };
                    };
                };
                case (isClass (configFile >> "CfgVehicles" >> _x)): {
                    if (getNumber (configFile >> "CfgVehicles" >> _x >> "isBackpack") == 1) then {
                        (_cargo select IDX_VIRT_BACKPACK) pushBackUnique _x;
                    };
                };
                case (isClass (configFile >> "CfgGlasses" >> _x)): {
                    (_cargo select IDX_VIRT_GOGGLES) pushBackUnique _x;
                };
            };
        };
    } foreach _items;
};

_object setVariable [QGVAR(virtualItems), _cargo, _global];
