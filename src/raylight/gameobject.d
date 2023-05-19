/++
Unity-style GameObject. Intended to be heavily used with [raylight.component] module.
+/
module raylight.gameobject;

import raylight.component.base;

// LINK: https://docs.unity3d.com/ScriptReference/GameObject.html

class GameObject {
    private IComponent[] _components;
    private string _name;
    private string[] _tags;
}
