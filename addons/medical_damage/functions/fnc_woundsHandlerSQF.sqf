/*
 * Author: Glowbal, commy2
 * Handling of the open wounds & injuries upon the handleDamage eventhandler.
 *
 * Arguments:
 * 0: Unit That Was Hit <OBJECT>
 * 1: Name Of Body Part <STRING>
 * 2: Amount Of Damage <NUMBER>
 * 3: Shooter or source of the damage <OBJECT>
 * 4: Type of the damage done <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */
#include "script_component.hpp"

params ["_unit", "_bodyPart", "_damage", "_typeOfProjectile", "_typeOfDamage"];
TRACE_5("start",_unit,_bodyPart,_damage,_typeOfProjectile,_typeOfDamage);

// Convert the selectionName to a number and ensure it is a valid selection.
private _bodyPartN = ALL_BODY_PARTS find toLower _bodyPart;
if (_bodyPartN < 0) exitWith {};

if (_typeOfDamage isEqualTo "") then {
    _typeOfDamage = "unknown";
};

// Get the damage type information. Format: [typeDamage thresholds, selectionSpecific, woundTypes]
// WoundTypes are the available wounds for this damage type. Format [[classID, selections, bleedingRate, pain], ..]
private _damageTypeInfo = [GVAR(allDamageTypesData) getVariable _typeOfDamage] param [0, [[], false, []]];
_damageTypeInfo params ["_thresholds", "_isSelectionSpecific", "_woundTypes"];

// It appears we are dealing with an unknown type of damage.
if (count _woundTypes == 0) then {
    // grabbing the configuration for unknown damage type
    _damageTypeInfo = [GVAR(allDamageTypesData) getVariable "unknown"] param [0, [[], false, []]];
    _woundTypes = _damageTypeInfo select 2;
};

// find the available injuries for this damage type and damage amount
private _highestPossibleSpot = -1;
private _highestPossibleDamage = -1;
private _allPossibleInjuries = [];

{
    _x params ["", "_selections", "", "", "_damageExtrema"];
    _damageExtrema params ["_minDamage", "_maxDamage"];

    // Check if the damage is higher as the min damage for the specific injury
    if (_damage >= _minDamage && {_damage <= _maxDamage || _maxDamage < 0}) then {
        // Check if the injury can be applied to the given selection name
        if ("All" in _selections || {_bodyPart in _selections}) then { // @todo, this is case sensitive!

            // Find the wound which has the highest minimal damage, so we can use this later on for adding the correct injuries
            if (_minDamage > _highestPossibleDamage) then {
                _highestPossibleSpot = _forEachIndex;
                _highestPossibleDamage = _minDamage;
            };

            // Store the valid possible injury for the damage type, damage amount and selection
            _allPossibleInjuries pushBack _x;
        };
    };
} forEach _woundTypes;

// No possible wounds available for this damage type or damage amount.
if (_highestPossibleSpot < 0) exitWith {};

// Administration for open wounds and ids
private _openWounds = _unit getVariable [QEGVAR(medical,openWounds), []];
private _woundID = _unit getVariable [QGVAR(lastUniqueWoundID), 1];

private _painLevel = 0;
private _bodyPartDamage = _unit getVariable [QEGVAR(medical,bodyPartDamage), [0,0,0,0,0,0]];
private _woundsCreated = [];
{
    if (_x select 0 <= _damage) exitWith {
        for "_i" from 0 to ((_x select 1)-1) do {
            // Find the injury we are going to add. Format [ classID, allowdSelections, bleedingRate, injuryPain]
            private _oldInjury = if (random 1 >= 0.85) then {
                _woundTypes select _highestPossibleSpot
            } else {
                selectRandom _allPossibleInjuries
            };

            _oldInjury params ["_woundClassIDToAdd", "", "_injuryBleedingRate", "_injuryPain"];

            private _bodyPartNToAdd = [floor random 6, _bodyPartN] select _isSelectionSpecific; // 6 == count ALL_BODY_PARTS
            
            _bodyPartDamage set [_bodyPartNToAdd, (_bodyPartDamage select _bodyPartNToAdd) + _damage];
            
            // Create a new injury. Format [ID, classID, bodypart, percentage treated, bleeding rate]
            _injury = [_woundID, _woundClassIDToAdd, _bodyPartNToAdd, 1, _injuryBleedingRate];

            // The higher the nastiness likelihood the higher the change to get a painful and bloody wound 
            private _nastinessLikelihood = if (_damage > 1) then {
                (_damage ^ 0.33)
            } else {
                (0.1 max _damage)
            };
            private _bloodiness   = 0.01 + 0.99 * (1 - random[0, 1, 0.9]) ^ (1 / _nastinessLikelihood);
            private _painfullness = 0.05 + 0.95 * (1 - random[0, 1, 0.5]) ^ (1 / _nastinessLikelihood);

            _bleeding = _injuryBleedingRate * _bloodiness;

            _injury set [4, _bleeding];
            _injury set [5, _damage];

            private _pain = _injuryPain * _painfullness;
            _painLevel = _painLevel max _pain;

#ifdef DEBUG_MODE_FULL
            systemChat format["%1, damage: %2, peneration: %3, bleeding: %4, pain: %5", _bodyPart, round(_damage * 100) / 100, _damage > PENETRATION_THRESHOLD, round(_bleeding * 1000) / 1000, round(_pain * 1000) / 1000];
#endif

            if (_bodyPartNToAdd == 0 && {_damage > LETHAL_HEAD_DAMAGE_THRESHOLD}) then {
                [QEGVAR(medical,FatalInjury), _unit] call CBA_fnc_localEvent;
            };

            // todo `forceWalk` based on leg damage
            private _causeLimping = (GVAR(woundsData) select _woundClassIDToAdd) select 7;
            if (_causeLimping == 1 && {_damage > LIMPING_DAMAGE_THRESHOLD} && {_bodyPartNToAdd > 3}) then {
                [_unit, true] call EFUNC(medical_engine,setLimping);
            };

            // if possible merge into existing wounds
            private _createNewWound = true;
            {
                _x params ["", "_classID", "_bodyPartN", "_oldAmountOf", "_oldBleeding", "_oldDamage"];
                if (_woundClassIDToAdd == _classID && {_bodyPartNToAdd == _bodyPartN && {(_damage < PENETRATION_THRESHOLD) isEqualTo (_oldDamage < PENETRATION_THRESHOLD)}}) then {
                    private _oldCategory = (floor ((0 max _oldBleeding min 0.1) / 0.05));
                    private _newCategory = (floor ((0 max _bleeding min 0.1) / 0.05));
                    if (_oldCategory == _newCategory) exitWith {
                        private _newAmountOf = _oldAmountOf + 1;
                        _x set [3, _newAmountOf];
                        private _newBleeding = (_oldAmountOf * _oldBleeding + _bleeding) / _newAmountOf;
                        _x set [4, _newBleeding];
                        private _newDamage = (_oldAmountOf * _oldDamage + _damage) / _newAmountOf;
                        _x set [5, _newDamage];
                        _createNewWound = false;
                    };
                };
            } forEach _openWounds;

            if (_createNewWound) then {
                _openWounds pushBack _injury;
            };

            // New injuries will also increase the wound ID
            _woundID = _woundID + 1;

            // Store the injury so we can process it later correctly.
            _woundsCreated pushBack _injury;
        };
    };
} forEach _thresholds;

_unit setVariable [QEGVAR(medical,openWounds), _openWounds, true];
_unit setVariable [QEGVAR(medical,bodyPartDamage), _bodyPartDamage, true];

[_unit, _bodyPart] call EFUNC(medical_engine,updateBodyPartVisuals);

// Only update if new wounds have been created
if (count _woundsCreated > 0) then {
    _unit setVariable [QEGVAR(medical,lastUniqueWoundID), _woundID, true];
    [_unit] call EFUNC(medical,handleIncapacitation);
};

[_unit, _painLevel] call EFUNC(medical,adjustPainLevel);
[_unit, "hit", PAIN_TO_SCREAM(_painLevel)] call EFUNC(medical_engine,playInjuredSound);

TRACE_5("exit",_unit,_painLevel,_unit getVariable QEGVAR(medical,pain),_unit getVariable QEGVAR(medical,openWounds),_woundsCreated);