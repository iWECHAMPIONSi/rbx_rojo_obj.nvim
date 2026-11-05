## ChangeLog

## Changes:
* Clarified that the Property is unable to export, not the entire Class
* Fixed diff.py because I acutally had to use it this time

## Roblox API Changes Effective to Plugin
CHANGED CLASS: AnimationPlayer
    NEW PROPERTY: Parameters
NEW CLASS: TextChannelWindow
CHANGED CLASS: BillboardGui
    NEW PROPERTY: InputSinkEnabled
CHANGED CLASS: ScreenGui
    NEW PROPERTY: InputSinkEnabled
CHANGED CLASS: AdGui
    NEW PROPERTY: InputSinkEnabled
CHANGED CLASS: SurfaceGui
    NEW PROPERTY: InputSinkEnabled
CHANGED CLASS: TeleportOptions
    REMOVED PROPERTY: ReservedServerAccessCode -> \['Deprecated', 'Readonly']
    REMOVED PROPERTY: ShouldReserveServer -> \['Deprecated']
CHANGED CLASS: UIGradient
    CHANGED PROPERTY: Scale
        Tags: \['NotBrowsable'] -> []
    CHANGED PROPERTY: TileMode
        Tags: \['NotBrowsable'] -> []
    CHANGED PROPERTY: Type
        Tags: \['NotBrowsable'] -> []
CHANGED ENUM: AnimationValueNodeType
    NEW ENUM FIELD: FeatureMatching
CHANGED ENUM: AvatarUnificationMode
    REMOVED ENUM FIELD: AvatarUnificationMode.Default -> \['Deprecated']
    REMOVED ENUM FIELD: AvatarUnificationMode.Disabled -> \['Deprecated']
    REMOVED ENUM FIELD: AvatarUnificationMode.Enabled -> \['Deprecated']
NEW ENUM: FeatureMatchingSource
NEW ENUM: FeatureSelectionMode
CHANGED ENUM: PartType
    NEW ENUM FIELD: Capsule
NEW ENUM: PlayerDeviceTrustDecision
NEW ENUM: PlayerDeviceTrustLevel
NEW ENUM: SerializationFormat
REMOVED ENUM: PrimalPhysicsSolver -> REMOVED
