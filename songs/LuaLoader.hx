import funkin.backend.utils.NdllUtil;
import Lua;
import Type;
import haxe.io.Path;
import Reflect;

var luascripts = [];
public var modchartSprites:Map<String, FunkinSprite> = [];
public var modchartTexts:Map<String, FlxText> = [];
public var variables:Map<String, Dynamic> = [];
// var currentVars = null;

function create() {
    for(i in Paths.getFolderContent("songs/"+PlayState.instance.SONG.meta.name+"/scripts"))
        if(Path.extension(i).toLowerCase() == "cnelua")
            create_lua("songs/"+PlayState.instance.SONG.meta.name+"/scripts/"+i);
    
}

function postCreate() {
    callOnScripts("onCreatePost", {});
}

function onPlayerHit(e) {
    callOnScripts("goodNoteHit", [e.note.strumLine.notes.members.indexOf(e.note), e.note.noteData, e.note.noteType, e.note.isSustainNote]);
}

function update(e) {
    callOnScripts("onUpdate", [e]);
}

function create_lua(path)
{
    
    var lua = new Lua();
	lua.self = lua;
	lua.create();
    createCallbacks(lua);
    var res = lua.execute(Assets.getText(Paths.getPath(path)));
    lua.call("onCreate", {});

    luascripts.push(lua);

}

function callOnScripts(func, args)
{
    for(script in luascripts)
        script.call(func, args);
    
}

function createCallbacks(lua) {

    lua.add_callback('debugPrint', function(text) {trace("From lua: "+text); return true;});

    lua.add_callback('getProperty', function(variable:String, ?allowMaps:Bool = false) {
        var split:Array<String> = variable.split('.');
        if(split.length > 1)
            return lua.haxe_to_lua(getVarInArray(getPropertyLoop(split, true, true, allowMaps), split[split.length-1], allowMaps), lua.handle);
        return lua.haxe_to_lua(getVarInArray(PlayState.instance, variable, allowMaps), lua.handle);
    });

    lua.add_callback("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false) {
		var split = variable.split('.');
		if(split.length > 1) {
			setVarInArray(getPropertyLoop(split, true, true, allowMaps), split[split.length-1], value, allowMaps);
			return true;
		}
		setVarInArray(getTargetInstance(), variable, value, allowMaps);
		return true;
	});

    lua.add_callback("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false) {
		var split:Array<String> = obj.split('.');
		var realObject:Dynamic = null;
		if(split.length > 1)
			realObject = getPropertyLoop(split, true, false, allowMaps);
		else
			realObject = Reflect.getProperty(getTargetInstance(), obj);

		if(Std.isOfType(realObject, FlxTypedGroup)) {
			setGroupStuff(realObject.members[index], variable, value, allowMaps);
			return value;
		}

		var leArray:Dynamic = realObject[index];
		if(leArray != null) {
			if(Type.typeof(variable) == ValueType.TInt) {
				leArray[variable] = value;
				return value;
			}
			setGroupStuff(leArray, variable, value, allowMaps);
		}
		return value;
	});

    lua.add_callback("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
		tag = StringTools.replace(tag, '.', '');
		resetSpriteTag(tag);
		var leSprite = new FlxSprite(x, y);
		if(image != null && image.length > 0)
		{
			leSprite.loadGraphic(Paths.image(image));
		}
		modchartSprites.set(tag, leSprite);
		variables.set(tag,leSprite);
		leSprite.active = true;
	});

    lua.add_callback("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color) {
		var spr:FlxSprite = getObjectDirectly(obj, false);
        trace(spr);
		if(spr != null) spr.makeGraphic(width, height, colorFromString(color));
	});

    lua.add_callback("addLuaSprite", function(tag:String, front:Bool = false) {
		var mySprite:FlxSprite = null;
		if(modchartSprites.exists(tag)) mySprite = modchartSprites.get(tag);
		else if(variables.exists(tag)) mySprite = variables.get(tag);

		if(mySprite == null) return false;
        front = true;
		if(front)
			add(mySprite);
		else
		{
			// if(!game.isDead)
			// 	game.insert(game.members.indexOf(getLowestCharacterGroup()), mySprite);
			// else
			// 	GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
		}
		return true;
	});

    lua.add_callback("setGraphicSize", function(obj:String, x:Float, y:Float = 0, updateHitbox:Bool = true) {
        if(getLuaObject(obj)!=null) {
            var shit:FlxSprite = getLuaObject(obj);
            shit.setGraphicSize(x, y);
            if(updateHitbox) shit.updateHitbox();
            return;
        }

        var split:Array<String> = obj.split('.');
        var poop:FlxSprite = getObjectDirectly(split[0]);
        if(split.length > 1) {
            poop = getVarInArray(getPropertyLoop(split), split[split.length-1]);
        }

        if(poop != null) {
            poop.setGraphicSize(x, y);
            if(updateHitbox) poop.updateHitbox();
            return;
        }
        trace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
    });

    lua.add_callback("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
        if(getLuaObject(obj)!=null) {
            var shit:FlxSprite = getLuaObject(obj);
            shit.scale.set(x, y);
            if(updateHitbox) shit.updateHitbox();
            return;
        }

        var split:Array<String> = obj.split('.');
        var poop:FlxSprite = getObjectDirectly(split[0]);
        if(split.length > 1) {
            poop = getVarInArray(getPropertyLoop(split), split[split.length-1]);
        }

        if(poop != null) {
            poop.scale.set(x, y);
            if(updateHitbox) poop.updateHitbox();
            return;
        }
        trace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
    });

    lua.add_callback("updateHitbox", function(obj:String) {
        if(getLuaObject(obj)!=null) {
            var shit:FlxSprite = getLuaObject(obj);
            shit.updateHitbox();
            return;
        }

        var split:Array<String> = obj.split('.');
        var poop:FlxSprite = getObjectDirectly(split[0]);
        if(split.length > 1) {
            poop = getVarInArray(getPropertyLoop(split), split[split.length-1]);
        }

        if(poop != null) {
            poop.updateHitbox();
            return;
        }
        trace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
    });

    lua.add_callback("removeLuaSprite", function(tag:String, destroy:Bool = true, ?group:String = null) {
        var obj:FlxSprite = getObjectDirectly(tag);
        if(obj == null || obj.destroy == null)
            return;
        
        var groupObj:Dynamic = null;
        if(group == null) groupObj = getTargetInstance();
        else groupObj = getObjectDirectly(group);

        groupObj.remove(obj, true);
        if(destroy)
        {
            MusicBeatState.getVariables().remove(tag);
            obj.destroy();
        }
    });

    lua.add_callback("setObjectCamera", function(obj:String, camera:String = 'game') {
        var real:FlxBasic = getLuaObject(obj);
        if(real != null) {
            real.cameras = [cameraFromString(camera)];
            return true;
        }

        var split:Array<String> = obj.split('.');
        var object:FlxBasic = getObjectDirectly(split[0]);
        if(split.length > 1) {
            object = getVarInArray(getPropertyLoop(split), split[split.length-1]);
        }

        if(object != null) {
            object.cameras = [cameraFromString(camera)];
            return true;
        }
        luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
        return false;
    });
    // lua.add_callback("setBlendMode", function(obj:String, blend:String = '') {
    //     var real:FlxSprite = game.getLuaObject(obj);
    //     if(real != null) {
    //         real.blend = blendModeFromString(blend);
    //         return true;
    //     }

    //     var split:Array<String> = obj.split('.');
    //     var spr:FlxSprite = getObjectDirectly(split[0]);
    //     if(split.length > 1) {
    //         spr = getVarInArray(getPropertyLoop(split), split[split.length-1]);
    //     }

    //     if(spr != null) {
    //         spr.blend = blendModeFromString(blend);
    //         return true;
    //     }
    //     luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
    //     return false;
    // });

    // lua.add_callback("luaSpriteExists", function(tag:String) {
    //     var obj:FlxSprite = Reflect.field(PlayState.instance, tag);
    //     return (obj != null && (Std.isOfType(obj, FunkinSprite) || Std.isOfType(obj, FlxSprite)));
    // });
    // lua.add_callback("luaTextExists", function(tag:String) {
    //     var obj:FlxText = Reflect.field(PlayState.instance, tag);
    //     return (obj != null && Std.isOfType(obj, FlxText));
    // });
    // lua.add_callback("luaSoundExists", function(tag:String) {
    //     var obj:FlxSound = Reflect.field(PlayState.instance, "sound_"+tag);
    //     return (obj != null && Std.isOfType(obj, FlxSound));
    // });
}

// lua utils functions

public function getTargetInstance()
{
    return PlayState.instance;
}

function isMap(variable)
{
    if(variable.exists != null && variable.keyValueIterator != null) return true;
    return false;
}

public function getLuaObject(tag, ?text) {
    if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
    if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
    if(variables.exists(tag)) return variables.get(tag);
    return null;
}

function getObjectDirectly(objectName, ?checkForTextsToo = true, ?allowMaps = false)
{
    switch(objectName)
    {
        case 'this' | 'instance' | 'game':
            return PlayState.instance;
        
        default:
            var obj = getLuaObject(objectName, checkForTextsToo);
            if(obj == null) obj = getVarInArray(PlayState.instance, objectName, allowMaps);
            return obj;
    }
}

function getVarInArray(instance, variable, allowMaps = false)
{
    var splitProps:Array<String> = variable.split('[');
    
    if(splitProps.length > 1)
    {
        var target:Dynamic = null;
        if(variables.exists(splitProps[0]))
        {
            var retVal:Dynamic = variables.get(splitProps[0]);
            if(retVal != null)
                target = retVal;
        }
        else
            target = Reflect.getProperty(instance, splitProps[0]);
        for (i in 1...splitProps.length)
        {
            var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
            target = target[j];
        }
        return target;
    }
    
    if(allowMaps && isMap(instance))
    {
        //trace(instance);
        return instance.get(variable);
    }
    if(variables.exists(variable))
    {
        var retVal:Dynamic = variables.get(variable);
        if(retVal != null)
            return retVal;
    }
    return Reflect.getProperty(instance, variable);
}

function getPropertyLoop(split:Array<String>, ?checkForTextsToo = true, ?getProperty = true, ?allowMaps = false)
{
    var obj = getObjectDirectly(split[0], checkForTextsToo);
    var end = split.length;
    if(getProperty) end = split.length-1;
    for (i in 1...end) obj = getVarInArray(obj, split[i], allowMaps);
    return obj;
}

function setVarInArray(instance, variable, value, allowMaps)
{
    var splitProps = variable.split('[');
    if(splitProps.length > 1)
    {
        var target = null;
        if(variables.exists(splitProps[0]))
        {
            var retVal = variables.get(splitProps[0]);
            if(retVal != null)
                target = retVal;
        }
        else target = Reflect.getProperty(instance, splitProps[0]);
        for (i in 1...splitProps.length)
        {
            var j = splitProps[i].substr(0, splitProps[i].length - 1);
            if(i >= splitProps.length-1) //Last array
                target[j] = value;
            else //Anything else
                target = target[j];
        }
        return target;
    }
    if(allowMaps && isMap(instance))
    {
        //trace(instance);
        instance.set(variable, value);
        return value;
    }
    if(variables.exists(variable))
    {
        variables.set(variable, value);
        return value;
    }
    Reflect.setProperty(instance, variable, value);
    return value;
}

function resetSpriteTag(tag) {
    if(!modchartSprites.exists(tag)) {
        return;
    }

    var target = modchartSprites.get(tag);
    target.kill();
    remove(target, true);
    target.destroy();
    modchartSprites.remove(tag);
}

public function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false) {
    var split = variable.split('.');
    if(split.length > 1) {
        var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
        for (i in 1...split.length-1)
            obj = Reflect.getProperty(obj, split[i]);

        leArray = obj;
        variable = split[split.length-1];
    }
    if(allowMaps && isMap(leArray)) leArray.set(variable, value);
    else Reflect.setProperty(leArray, variable, value);
    return value;
}

// psych coolutil functions 

public static function colorFromString(color:String) // THIS DOES NOT WORK
{
    var hideChars = "[\t\n\r]";
    var color:String = color;
    trace("cololr: "+color);
    if(StringTools.startsWith(color,'0x')) color = color.substring(color.length - 6);
    trace("making color");
    var colorNum:Null<FlxColor> = FlxColor.fromString(color);
    trace("yea");
    if(colorNum == null) colorNum = FlxColor.fromString('#'+color);

    trace(colorNum);

    return colorNum != null ? colorNum : FlxColor.WHITE;
}

function cameraFromString(cam:String) {
    switch(cam.toLowerCase()) {
        case 'camgame' | 'game' | 'camGame': return PlayState.instance.camGame;
        case 'camhud' | 'hud' | 'camHUD': return PlayState.instance.camHUD;
        // case 'camother' | 'other'| 'camOther': return PlayState.instance.camOther;
        default: return null;
    }
    // var camera:FlxCamera = MusicBeatState.getVariables().get(cam);
    // if (camera == null || !Std.isOfType(camera, FlxCamera)) camera = PlayState.instance.camGame;
    // return camera;
}