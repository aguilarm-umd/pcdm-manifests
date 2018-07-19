require 'erb'

module IIIF
  class Page
    attr_accessor :id, :label, :image, :uri
  end

  class Image
    attr_accessor :id, :width, :height, :uri
  end

  class Item

    def encode(str)
      ERB::Util.url_encode(str)
    end

    def base_uri
    end

    def query
    end

    def is_manifest_level?
    end

    def is_canvas_level?
    end

    def pages
      []
    end

    def label
    end

    def date
    end

    def license
    end

    def attribution
    end

    def metadata
      {}
    end

    def annotation_list(uri, annotations)
      {
        "@context"  => "http://iiif.io/api/presentation/2/context.json",
        "@id"       => uri,
        "@type"     => "sc:AnnotationList",
        "resources" => annotations
      }
    end

    def canvases
      pages.map do |page|
        image = page.image
        {
          '@id' => canvas_uri(page.id),
          '@type' => 'sc:Canvas',
          'label' => page.label,
          'height' => image.height,
          'width' => image.width,

          'images' => [
            {
              '@id' => annotation_uri(image.id),
              '@type' => 'oa:Annotation',
              'motivation' => 'sc:painting',
              'resource' => {
                '@id' => image_uri(image.id),
                '@type' => 'dctypes:Image',
                'format' => 'image/jpeg',
                'service' => {
                  '@context' => 'http://iiif.io/api/image/2/context.json',
                  '@id' => image_uri(image.id),
                  'profile' => 'http://iiif.io/api/image/2/profiles/level2.json'
                },
                'height' => image.height,
                'width' => image.width,
              },
              'on' => canvas_uri(page.id)
            }
          ],
          'otherContent' => other_content(page)
        }
      end
    end

    def other_content(page)
      [].tap do |other|
        if methods.include?(:textblock_list)
          other.push({
            '@id' => list_uri(page.id),
            '@type' => 'sc:AnnotationList'
          })
        end
        if query && methods.include?(:search_hit_list)
          other.push({
            '@id' => list_uri(page.id) + '?q=' + encode(query),
            '@type' => 'sc:AnnotationList',
          })
        end
      end
    end

    def manifest
      {
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => manifest_uri,
        '@type' => 'sc:Manifest',
        'label' => label,
        'metadata' => metadata,
        'navDate' => date,
        'license' => license,
        'attribution' => attribution,
        'sequences' => [],
        'thumbnail' => {},
        'logo' => {
          '@id' => 'https://www.lib.umd.edu/images/wrapper/liblogo.png'
        }
      }.tap do |manifest|
        if pages.length > 0
          first_page = pages[0]
          first_image = first_page.image

          manifest['thumbnail'] = {
            '@id' => image_uri(first_image.id, size: '80,100'),
            'service' => {
              '@context' => 'http://iiif.io/api/image/2/context.json',
              '@id' => image_uri(first_image.id),
              'profile' => 'http://iiif.io/api/image/2/level1.json'
            }
          }
          manifest['sequences'] = [
            {
              '@id' => sequence_uri('normal'),
              '@type' => 'sc:Sequence',
              'label' => 'Current Page Order',
              'startCanvas' => canvas_uri(first_page.id),
              'canvases' => canvases
            }
          ]
        end
      end
    end

    def manifest_uri
      base_uri + 'manifest'
    end

    def canvas_uri(page_id)
      base_uri + 'canvas/' + page_id
    end

    def annotation_uri(doc_id)
      base_uri + 'annotation/' + doc_id
    end

    def list_uri(page_id)
      base_uri + 'list/' + page_id
    end

    def sequence_uri(label)
      base_uri + 'sequence/' + label
    end

    def fragment_selector(value)
      {
        '@type' => 'oa:FragmentSelector',
        'value' => value
      }
    end

    def specific_resource(param = {})
      {
        '@type' => 'oa:SpecificResource',
        'selector' => param[:selector],
        'full' => param[:full]
      }
    end

    def text_body(param = {})
      {
        '@type' => 'cnt:ContentAsText',
        'format' => param[:format] || 'text/plain',
        'chars' => param[:text]
      }
    end

    def annotation(param = {})
      {
        '@id' => param[:id],
        '@type' => ['oa:Annotation', param[:type]],
        'on' => param[:target],
        'motivation' => param[:motivation]
      }.tap do |annotation|
        annotation['resource'] = param[:body] if param[:body]
      end
    end

    DEFAULT_IIIF_PARAMS = {
      region: 'full',
      size: 'full',
      rotation: 0,
      quality: 'default',
      format: 'jpg'
    }

    def image_uri(image_id, param={})
      uri = "#{image_base_uri}#{image_id}"
      if param.empty?
        uri
      else
        p = DEFAULT_IIIF_PARAMS.merge(param)
        uri + "/#{p[:region]}/#{p[:size]}/#{p[:rotation]}/#{p[:quality]}.#{p[:format]}"
      end
    end
  end
end