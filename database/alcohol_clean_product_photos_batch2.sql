with photos(id,image_url) as (values
('c98fcf3a-96af-59c6-9182-bec47aae93f7'::uuid,'./assets/menu-photos/alcohol-clean-v1/c98fcf3a-96af-59c6-9182-bec47aae93f7.webp'),
('25c0c070-3406-52aa-94e1-1900c5ee3e75'::uuid,'./assets/menu-photos/alcohol-clean-v1/25c0c070-3406-52aa-94e1-1900c5ee3e75.webp'),
('f0ea0ef3-2579-579f-bfe3-2a35a0af8ec1'::uuid,'./assets/menu-photos/alcohol-clean-v1/f0ea0ef3-2579-579f-bfe3-2a35a0af8ec1.webp'),
('55d7e461-fc84-5042-91af-e1acb4102aab'::uuid,'./assets/menu-photos/alcohol-clean-v1/55d7e461-fc84-5042-91af-e1acb4102aab.webp'),
('3c16ff3b-2519-5e88-8d69-b1be40ae7bac'::uuid,'./assets/menu-photos/alcohol-clean-v1/3c16ff3b-2519-5e88-8d69-b1be40ae7bac.webp'),
('7de99059-4efb-5820-b637-13e461e70ce2'::uuid,'./assets/menu-photos/alcohol-clean-v1/7de99059-4efb-5820-b637-13e461e70ce2.webp'),
('a5777086-cac5-50bb-85ac-02ce428d6d20'::uuid,'./assets/menu-photos/alcohol-clean-v1/a5777086-cac5-50bb-85ac-02ce428d6d20.webp'),
('43c06f00-9467-541e-82cf-1f2a0d762a08'::uuid,'./assets/menu-photos/alcohol-clean-v1/43c06f00-9467-541e-82cf-1f2a0d762a08.webp'),
('16d9f782-c3a5-5a81-bbc9-edc380dacf20'::uuid,'./assets/menu-photos/alcohol-clean-v1/16d9f782-c3a5-5a81-bbc9-edc380dacf20.webp'),
('6d890a13-48f6-5882-a07d-b28376e419c5'::uuid,'./assets/menu-photos/alcohol-clean-v1/6d890a13-48f6-5882-a07d-b28376e419c5.webp'),
('3cbc657f-9ab8-5ae6-b0e0-500c5f15dd27'::uuid,'./assets/menu-photos/alcohol-clean-v1/3cbc657f-9ab8-5ae6-b0e0-500c5f15dd27.webp'),
('f092de0c-b07f-5bdc-9a29-ee1d87eb96be'::uuid,'./assets/menu-photos/alcohol-clean-v1/f092de0c-b07f-5bdc-9a29-ee1d87eb96be.webp'),
('02f43742-3657-5692-ac6b-5557f308a3f9'::uuid,'./assets/menu-photos/alcohol-clean-v1/02f43742-3657-5692-ac6b-5557f308a3f9.webp'))
update public.products p set image_url=photos.image_url from photos where p.id=photos.id and p.vendor_id='0fda82be-7bde-5187-9a15-0d8f12bbcd73' returning p.id,p.name;
