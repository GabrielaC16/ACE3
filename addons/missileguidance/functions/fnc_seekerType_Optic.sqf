#define DEBUG_MODE_FULL
#include "script_component.hpp"

EXPLODE_7_PVT(((_this select 1) select 0),_shooter,_weapon,_muzzle,_mode,_ammo,_magazine,_projectile);
private["_targets", "_foundTargetPos", "_launchParams", "_seekerParams", "_targetLaunchParams"];

_seekerTargetPos = _this select 0;

_launchParams = _this select 1;
_target = (((_launchParams select 1) select 1) select 0);
_seekerParams = _launchParams select 3;

TRACE_1("", _this);
TRACE_1("", _launchParams);

// TODO:: Make sure the missile maintains LOS
_foundTargetPos = [0,0,0];
if(!isNil "_target") then {
    _foundTargetPos = getPosASL _target;
};

TRACE_2("", _target, _foundTargetPos);

_foundTargetPos;