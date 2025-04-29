class LuaUtils {
    public function new() {}

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
        //if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
        if(variables.exists(tag)) return variables.get(tag);
        return null;
    }
    
    public function getObjectDirectly(objectName, ?checkForTextsToo = true, ?allowMaps = false)
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
    
    public function getVarInArray(instance, variable, allowMaps = false)
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
    
    public function getPropertyLoop(split:Array<String>, ?checkForTextsToo = true, ?getProperty = true, ?allowMaps = false)
    {
        var obj = getObjectDirectly(split[0], checkForTextsToo);
        var end = split.length;
        if(getProperty) end = split.length-1;
        for (i in 1...end) obj = getVarInArray(obj, split[i], allowMaps);
        return obj;
    }
    
    public function setVarInArray(instance, variable, value, allowMaps)
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
    
    public function resetSpriteTag(tag) {
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
    
    public function colorFromString(color:String) // THIS DOES NOT WORK
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
}