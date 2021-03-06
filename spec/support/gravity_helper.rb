def gravity_v1_artwork(options: {})
  {
    artist:
    {
      _id: 'artist-id',
      id: 'artist-slug',
      name: 'BNMOsy',
      years: 'born 1953',
      public: true,
      birthday: '1953',
      consignable: true,
      deathday: '',
      nationality: 'American',
      published_artworks_count: 382,
      forsale_artworks_count: 221,
      artworks_count: 502,
      original_width: nil,
      original_height: nil,
      image_url: 'http:///:version.jpg',
      image_versions: ['large', 'square'],
      image_urls:
        {
          large: 'http://large.jpg',
          square: 'http://square.jpg'
        }
      },
   partner:
    {
      partner_categories: [],
      _id: 'gravity-partner-id',
      id: 'gravity-partner-slug',
      default_profile_id: 'defualt-profile-id',
      default_profile_public: true,
      sortable_id: 'sortable-id',
      type: 'Gallery',
      name: 'BNMO',
      short_name: '',
      website: 'http://www.BNMO.com'
    },
   images:
    [{
      id: '54a08d8d7261692ce5c50300',
      position: 1,
      aspect_ratio: 0.69,
      downloadable: false,
      original_width: 412,
      original_height: 598,
      is_default: true,
      image_url:
       'https://d32dm0rphc51dk.cloudfront.net/EdrogYFIC2iS0H4myfs1Kw/:version.jpg',
      image_versions:
       ['small',
        'square',
        'tall'],
      image_urls:
       {
        small:
         'https:///small.jpg',
        square:
         'https:///square.jpg',
        tall:
         'https:///tall.jpg'},
      tile_size: 512,
      tile_overlap: 0,
      tile_format: 'jpg',
      tile_base_url:
       'https:///dztiles',
      max_tiled_height: 598,
      max_tiled_width: 412
    }],
   edition_sets:
    [{
      id: 'edition-set-id',
      forsale: true,
      sold: false,
      price: '4200',
      acquireable: false,
      dimensions: {in: '44 × 30 1/2 in', cm: '111.8 × 77.5 cm'},
      editions: 'Edition of 15',
      display_price_currency: 'USD (United States Dollar)',
      availability: 'for sale',
    }],
   artists:
    [{
      _id: 'artist-id',
      id: 'artist-slug',
      sortable_id: 'longo-robert',
      name: 'BNMOsy',
      years: 'born 1953',
      public: true,
      birthday: '1953',
      consignable: true,
      deathday: '',
      nationality: 'American',
      published_artworks_count: 382,
      forsale_artworks_count: 221,
      artworks_count: 502,
      original_width: nil,
      original_height: nil,
      image_url:
       'https://.../:version.jpg',
      image_versions: ['four_thirds', 'large', 'square', 'tall'],
      image_urls:
       {four_thirds:
         'https://.../four_thirds.jpg',
        large:
         'https://.../large.jpg',
        square:
         'https://.../square.jpg',
        tall:
         'https://.../tall.jpg'}
      }],
   _id: 'artwork-id',
   id: 'artwork-slug',
   title: 'Untitled Pl. 13 (from Men in the Cities)',
   display: 'BNMOsy, Untitled Pl. 13 (from Men in the Cities) (2005)',
   manufacturer: nil,
   category: 'Photography',
   medium: 'Rag paper',
   unique: nil,
   forsale: true,
   sold: false,
   date: '2005',
   dimensions: {in: '44 × 30 1/2 in', cm: '111.8 × 77.5 cm'},
   price: '5400',
   series: '',
   availability: 'for sale',
   availability_hidden: false,
   ecommerce: nil,
   tags: [],
   width: '30 1/2',
   height: '44',
   depth: '',
   diameter: nil,
   width_cm: 77.5,
   height_cm: 111.8,
   depth_cm: nil,
   diameter_cm: nil,
   metric: 'in',
   duration: nil,
   website: '',
   signature: '',
   default_image_id: 'default-image',
   edition_sets_count: 1,
   published: true,
   private: false,
   feature_eligible: false,
   price_currency: 'USD',
   inquireable: true,
   acquireable: false,
   published_at: '2015-01-08T19:29:54+00:00',
   deleted_at: nil,
   publisher: nil,
   comparables_count: 12,
   cultural_maker: nil,
   sale_ids: [],
   attribution_class: 'limited edition'
  }.merge(options).with_indifferent_access
end
