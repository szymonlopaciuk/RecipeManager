module Jekyll
  class RenderGalleryTag < Liquid::Tag

    def initialize(tag_name, pix, tokens)
      super
      @pix = pix
    end

    def render(context)
      @pix
    end
  end
end

Liquid::Template.register_tag('make_gallery', Jekyll::RenderGalleryTag)
