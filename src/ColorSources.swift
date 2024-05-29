import Foundation
import CxxStdlib
import OBSModule

public typealias OBSDataPtr = OpaquePointer
public typealias OBSSourcePtr = OpaquePointer
public typealias GSEffectPtr = OpaquePointer
public typealias ColorSourcePtr = UnsafeMutableRawPointer

public struct ColorSource {
  internal init(
    color: vec4 = .init(),
    colorSRGB: vec4 = .init(),
    width: UInt32 = 0,
    height: UInt32 = 0,
    src: OBSSourcePtr? = nil
  ) {
    self.color = color
    self.colorSRGB = colorSRGB
    self.width = width
    self.height = height
    self.src = src
  }

  public var color: vec4
  public var colorSRGB: vec4
  public var width: UInt32
  public var height: UInt32

  public var src: OBSSourcePtr?
}

enum ColorSourcePresets {
  static func makeColorSorucePresets() -> obs_source_info {
    var sourceInfo = obs_source_info()
    sourceInfo.id = "swift-color-source".obsString
    sourceInfo.version = 1
    sourceInfo.type = OBS_SOURCE_TYPE_INPUT
    sourceInfo.output_flags = UInt32(OBS_SOURCE_VIDEO | OBS_SOURCE_CUSTOM_DRAW | OBS_SOURCE_SRGB)
    sourceInfo.icon_type = OBS_ICON_TYPE_COLOR
    sourceInfo.get_name = Self.getName()
    sourceInfo.get_properties = Self.getProperties()
    sourceInfo.get_defaults = Self.getDefaults()
    sourceInfo.get_width = Self.getWidth()
    sourceInfo.get_height = Self.getHeight()
    sourceInfo.create = Self.create()
    sourceInfo.destroy = Self.destroy()
    sourceInfo.update = Self.update()
    sourceInfo.video_render = Self.videoRender()
    return sourceInfo
  }

  typealias CreateClosure = @convention(c) (OBSDataPtr?, OBSSourcePtr?) -> UnsafeMutableRawPointer?
  internal static func create() -> CreateClosure {
    return { settings, source in
      var colorSource = ColorSource(src: source)
      let color = UInt32(obs_data_get_int(settings, "color"))
      vec4_from_rgba(&colorSource.color, color)
      vec4_from_rgba_srgb(&colorSource.colorSRGB, color)
      colorSource.width = UInt32(obs_data_get_int(settings, "width"))
      colorSource.height = UInt32(obs_data_get_int(settings, "height"))
      return ObjectManager.shared.createSource(colorSource)
    }
  }
  typealias DestroyClosure = @convention(c) (ColorSourcePtr?) -> Void
  internal static func destroy() -> DestroyClosure {
    return { source in
      guard let source else { return }
      ObjectManager.shared.destroySource(source)
    }
  }
  typealias UpdateClosure = @convention(c) (ColorSourcePtr?, OBSDataPtr?) -> Void
  @Sendable internal static func update() -> UpdateClosure {
    return { source, settings in
      guard let source else { return }
      var colorSource = withUnsafeBound(to: ColorSource.self, ptr: source) { $0 }
      let color = UInt32(obs_data_get_int(settings, "color"))
      vec4_from_rgba(&colorSource.color, color)
      vec4_from_rgba_srgb(&colorSource.colorSRGB, color)
      colorSource.width = UInt32(obs_data_get_int(settings, "width"))
      colorSource.height = UInt32(obs_data_get_int(settings, "height"))
      withUnsafeBound(to: ColorSource.self, ptr: source) {
        $0 = colorSource
      }
    }
  }
  typealias VideoRenderClosure = @convention(c) (ColorSourcePtr?, GSEffectPtr?) -> Void
  internal static func videoRender() -> VideoRenderClosure {

    func helper(context: ColorSource, colorVal: inout vec4) {
      let solid = obs_get_base_effect(OBS_EFFECT_SOLID)
      let color = gs_effect_get_param_by_name(solid, "color")
      let tech = gs_effect_get_technique(solid, "Solid")
      gs_effect_set_vec4(color, &colorVal)

      gs_technique_begin(tech)
      gs_technique_begin_pass(tech, 0)

      gs_draw_sprite(.init(bitPattern: 0), 0, context.width, context.height)

      gs_technique_end_pass(tech)
      gs_technique_end(tech)
    }

    return { source, _ in
      guard let source else { return }
      let colorSource = withUnsafeBound(to: ColorSource.self, ptr: source) { $0 }
      let isLinearSRGB = gs_get_linear_srgb() || (colorSource.color.w < 1.0)
      let previous = gs_framebuffer_srgb_enabled()
      gs_enable_framebuffer_srgb(isLinearSRGB)

      let colorKeyPath = isLinearSRGB
        ? \ColorSource.colorSRGB
        : \ColorSource.color
      var color = colorSource[keyPath: colorKeyPath]
      helper(context: colorSource, colorVal: &color)
      withUnsafeBound(to: ColorSource.self, ptr: source) { source in
        source[keyPath: colorKeyPath] = color
      }
      gs_enable_framebuffer_srgb(previous)
    }
  }

  typealias GetNameClosure = @convention(c) (UnsafeMutableRawPointer?) -> UnsafePointer<CChar>?
  internal static func getName() -> GetNameClosure {
    return { _ in
      return obs_module_text("ColorSource.Name")
    }
  }

  typealias GetPropertiesClosure = @convention(c) (UnsafeMutableRawPointer?) -> OpaquePointer?
  internal static func getProperties() -> GetPropertiesClosure {
    return { _ in
      let ctx = obs_properties_create()
      obs_properties_add_color_alpha(ctx, "color", obs_module_text("ColorSource.Color"))
      obs_properties_add_int(ctx, "width", obs_module_text("ColorSource.Width"), 0, 4096, 1)
      obs_properties_add_int(ctx, "height", obs_module_text("ColorSource.Height"), 0, 4096, 1)
      return ctx
    }
  }

  typealias GetDefaultsClosure = @convention(c) (OpaquePointer?) -> Void
  internal static func getDefaults() -> GetDefaultsClosure {
    return { settings in
      obs_data_set_default_int(settings, "color", 0xFFD1D1D1)
      obs_data_set_default_int(settings, "width", 1920)
      obs_data_set_default_int(settings, "height", 1080)
    }
  }

  typealias GetSizeClosure = @convention(c) (UnsafeMutableRawPointer?) -> UInt32
  internal static func getWidth() -> GetSizeClosure {
    return { source in
      guard let source else { return 0 }
      return withUnsafeBound(to: ColorSource.self, ptr: source) { $0.width }
    }
  }
  internal static func getHeight() -> GetSizeClosure {
    return { source in
      guard let source else { return 0 }
      return withUnsafeBound(to: ColorSource.self, ptr: source) { $0.height }
    }
  }

  static func register() {
    var sourceInfo = makeColorSorucePresets()
    obs_register_source_s(&sourceInfo, MemoryLayout<obs_source_info>.size)
  }
}

