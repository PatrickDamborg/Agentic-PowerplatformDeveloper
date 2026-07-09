/*
*This is auto generated from the ControlManifest.Input.xml file
*/

// Define IInputs and IOutputs Type. They should match with ControlManifest.
export interface IInputs {
    boundValue: ComponentFramework.PropertyTypes.StringProperty;
    showInlinePreview: ComponentFramework.PropertyTypes.TwoOptionsProperty;
    clientId: ComponentFramework.PropertyTypes.StringProperty;
    tenantId: ComponentFramework.PropertyTypes.StringProperty;
    redirectUri: ComponentFramework.PropertyTypes.StringProperty;
    autoExpand: ComponentFramework.PropertyTypes.TwoOptionsProperty;
    previewHeight: ComponentFramework.PropertyTypes.WholeNumberProperty;
    browserPageSize: ComponentFramework.PropertyTypes.WholeNumberProperty;
    blockSharePointSharingLinks: ComponentFramework.PropertyTypes.TwoOptionsProperty;
    showOpenInWindow: ComponentFramework.PropertyTypes.TwoOptionsProperty;
    showNewTab: ComponentFramework.PropertyTypes.TwoOptionsProperty;
    showDownload: ComponentFramework.PropertyTypes.TwoOptionsProperty;
}
export interface IOutputs {
    boundValue?: string;
}
