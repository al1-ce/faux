// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/++
Unity-style GameObject. Intended to be heavily used with [faux.game.component] module.
+/
module faux.game.object;

import faux.game.component.base;

// LINK: https://docs.unity3d.com/ScriptReference/GameObject.html

class GameObject {
    private Component[] _components;
    private string _name;
    private string[] _tags;
}
