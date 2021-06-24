#include "script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Dedmen
 * Cache an array of all the compatible items for arsenal.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
*/

private _cargo = [
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
];

private _configCfgWeapons = configFile >> "CfgWeapons"; //Save this lookup in variable for perf improvement

{
    private _configItemInfo = _x >> "ItemInfo";
    private _simulationType = getText (_x >> "simulation");
    private _className = configName _x;
    private _hasItemInfo = isClass (_configItemInfo);
    private _itemInfoType = if (_hasItemInfo) then {getNumber (_configItemInfo >> "type")} else {0};

    switch true do {
        /* Weapon acc */
        case (
                _hasItemInfo &&
                {_itemInfoType in [TYPE_MUZZLE, TYPE_OPTICS, TYPE_FLASHLIGHT, TYPE_BIPOD]} &&
                {!(configName _x isKindOf ["CBA_MiscItem", (_configCfgWeapons)])}
            ): {

            //Convert type to array index
            (_cargo select IDX_VIRT_ATTACHMENTS) select ([TYPE_OPTICS,TYPE_FLASHLIGHT,TYPE_MUZZLE,TYPE_BIPOD] find _itemInfoType) pushBackUnique _className;
        };
        /* Headgear */
        case (_itemInfoType == TYPE_HEADGEAR): {
            (_cargo select IDX_VIRT_HEADGEAR) pushBackUnique _className;
        };
        /* Uniform */
        case (_itemInfoType == TYPE_UNIFORM): {
            (_cargo select IDX_VIRT_UNIFORM) pushBackUnique _className;
        };
        /* Vest */
        case (_itemInfoType == TYPE_VEST): {
            (_cargo select IDX_VIRT_VEST) pushBackUnique _className;
        };
        /* NVgs */
        case (_simulationType == "NVGoggles"): {
            (_cargo select IDX_VIRT_HMDS) pushBackUnique _className;
        };
        /* Binos */
        case (_simulationType == "Binocular" ||
        ((_simulationType == 'Weapon') && {(getNumber (_x >> 'type') == TYPE_BINOCULAR_AND_NVG)})): {
            (_cargo select IDX_VIRT_BINOS) pushBackUnique _className;
        };
        /* Map */
        case (_simulationType == "ItemMap"): {
            (_cargo select IDX_VIRT_MAP) pushBackUnique _className;
        };
        /* Compass */
        case (_simulationType == "ItemCompass"): {
            (_cargo select IDX_VIRT_COMPASS) pushBackUnique _className;
        };
        /* Radio */
        case (_simulationType == "ItemRadio"): {
            (_cargo select IDX_VIRT_RADIO) pushBackUnique _className;
        };
        /* Watch */
        case (_simulationType == "ItemWatch"): {
            (_cargo select IDX_VIRT_WATCH) pushBackUnique _className;
        };
        /* GPS */
        case (_simulationType == "ItemGPS" || (_itemInfoType == TYPE_UAV_TERMINAL)): {
            (_cargo select IDX_VIRT_GPS) pushBackUnique _className;
        };
        /* Weapon, at the bottom to avoid adding binos */
        case (isClass (_x >> "WeaponSlotsInfo") &&
            {getNumber (_x >> 'type') != TYPE_BINOCULAR_AND_NVG}): {
            private _weaponsArray = _cargo select IDX_VIRT_WEAPONS;
            private _baseWeapon = _className call bis_fnc_baseWeapon;

            switch (getNumber (_x >> "type")) do {
                case TYPE_WEAPON_PRIMARY: {
                    _weaponsArray select 0 pushBackUnique _baseWeapon;
                };
                case TYPE_WEAPON_SECONDARY: {
                    _weaponsArray select 1 pushBackUnique _baseWeapon;
                };
                case TYPE_WEAPON_HANDGUN: {
                    _weaponsArray select 2 pushBackUnique _baseWeapon;
                };
            };
        };
        /* Misc items */
        case (
                _hasItemInfo &&
                (_itemInfoType in [TYPE_MUZZLE, TYPE_OPTICS, TYPE_FLASHLIGHT, TYPE_BIPOD] &&
                {(_className isKindOf ["CBA_MiscItem", (_configCfgWeapons)])}) ||
                {_itemInfoType in [TYPE_FIRST_AID_KIT, TYPE_MEDIKIT, TYPE_TOOLKIT]} ||
                {(getText ( _x >> "simulation")) == "ItemMineDetector"}
            ): {
            (_cargo select IDX_VIRT_MISCELLANEOUS) pushBackUnique _className;
        };
    };
} foreach configProperties [_configCfgWeapons, "isClass _x && {(if (isNumber (_x >> 'scopeArsenal')) then {getNumber (_x >> 'scopeArsenal')} else {getNumber (_x >> 'scope')}) == 2} && {getNumber (_x >> 'ace_arsenal_hide') != 1}", true];

private _grenadeList = [];
{
    _grenadeList append getArray (_configCfgWeapons >> "Throw" >> _x >> "magazines");
} foreach getArray (_configCfgWeapons >> "Throw" >> "muzzles");

private _putList = [];
{
    _putList append getArray (_configCfgWeapons >> "Put" >> _x >> "magazines");
} foreach getArray (_configCfgWeapons >> "Put" >> "muzzles");

{
    private _className = configName _x;

    switch true do {
        // Rifle, handgun, secondary weapons mags
        case (
                ((getNumber (_x >> "type") in [TYPE_MAGAZINE_PRIMARY_AND_THROW,TYPE_MAGAZINE_SECONDARY_AND_PUT,1536,TYPE_MAGAZINE_HANDGUN_AND_GL,TYPE_MAGAZINE_MISSILE]) ||
                {(getNumber (_x >> QGVAR(hide))) == -1}) &&
                {!(_className in _grenadeList)} &&
                {!(_className in _putList)}
            ): {
            (_cargo select IDX_VIRT_MAGAZINES) pushBackUnique _className;
        };
        // Grenades
        case (_className in _grenadeList): {
            (_cargo select IDX_VIRT_GRENADE) pushBackUnique _className;
        };
        // Put
        case (_className in _putList): {
            (_cargo select IDX_VIRT_EXPLOSIVE) pushBackUnique _className;
        };
    };
} foreach configProperties [(configFile >> "CfgMagazines"), "isClass _x && {(if (isNumber (_x >> 'scopeArsenal')) then {getNumber (_x >> 'scopeArsenal')} else {getNumber (_x >> 'scope')}) == 2} && {getNumber (_x >> 'ace_arsenal_hide') != 1}", true];

{
    if (getNumber (_x >> "isBackpack") == 1) then {
        (_cargo select IDX_VIRT_BACKPACK) pushBackUnique (configName _x);
    };
} foreach configProperties [(configFile >> "CfgVehicles"), "isClass _x && {(if (isNumber (_x >> 'scopeArsenal')) then {getNumber (_x >> 'scopeArsenal')} else {getNumber (_x >> 'scope')}) == 2} && {getNumber (_x >> 'ace_arsenal_hide') != 1}", true];

{
    (_cargo select IDX_VIRT_GOGGLES) pushBackUnique (configName _x);
} foreach configProperties [(configFile >> "CfgGlasses"), "isClass _x && {(if (isNumber (_x >> 'scopeArsenal')) then {getNumber (_x >> 'scopeArsenal')} else {getNumber (_x >> 'scope')}) == 2} && {getNumber (_x >> 'ace_arsenal_hide') != 1}", true];

private _magazineGroups = [[],[]] call CBA_fnc_hashCreate;

private _cfgMagazines = configFile >> "CfgMagazines";

{
    private _magList = [];
    {
        private _magazines = (getArray _x) select {isClass (_cfgMagazines >> _x)}; //filter out non-existent magazines
        _magazines = _magazines apply {configName (_cfgMagazines >> _x)}; //Make sure classname case is correct
        _magList append _magazines;
    } foreach configProperties [_x, "isArray _x", true];

    [_magazineGroups, toLower configName _x, _magList arrayIntersect _magList] call CBA_fnc_hashSet;
} foreach configProperties [(configFile >> "CfgMagazineWells"), "isClass _x", true];

uiNamespace setVariable [QGVAR(configItems), _cargo];
uiNamespace setVariable [QGVAR(magazineGroups), _magazineGroups];
