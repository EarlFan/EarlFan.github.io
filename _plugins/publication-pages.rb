# frozen_string_literal: true

require 'jekyll/scholar'

module Jekyll
  class PublicationPdf < StaticFile
    def initialize(site, directory, source_pdf)
      super(site, site.source, directory, source_pdf.name)
      @source_pdf = source_pdf
    end

    def path
      @source_pdf.path
    end
  end

  class PublicationPages < Generator
    include Scholar::Utilities

    priority :normal

    def generate(site)
      @site = site
      @config = Scholar.defaults.merge(site.config.fetch('scholar'))

      entries.each do |entry|
        next unless entry[:details_page].to_s == 'true'

        paper = liquidify(entry)
        directory = "publications/#{entry.key}"
        page = PageWithoutAFile.new(site, site.source, directory, 'index.html')
        page.data.merge!(
          'layout' => 'publication',
          'title' => paper['title'],
          'permalink' => "/#{directory}/",
          'publication_key' => entry.key,
          'publication' => paper,
          'publication_authors' => paper.fetch('author_array').map do |author|
            author.values_at('first', 'von', 'last', 'jr').compact.reject(&:empty?).join(' ')
          end
        )

        if paper['pdf'] && !paper['pdf'].include?('://')
          source_pdf = site.static_files.find { |file| file.url == "/assets/pdf/#{paper['pdf']}" && file.extname.downcase == '.pdf' }
          if source_pdf
            pdf = PublicationPdf.new(site, directory, source_pdf)
            site.static_files << pdf
            page.data['publication_pdf_url'] = pdf.url
          else
            Jekyll.logger.warn 'Publication page:', "No local PDF for #{entry.key}."
          end
        end

        site.pages << page
      end
    end
  end
end
