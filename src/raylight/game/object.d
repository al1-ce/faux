/++
Unity-style GameObject. Intended to be heavily used with [raylight.game.component] module.
+/
module raylight.game.object;

import raylight.game.component.base;

// LINK: https://docs.unity3d.com/ScriptReference/GameObject.html

class GameObject {
    private Component[] _components;
    private string _name;
    private string[] _tags;
}
