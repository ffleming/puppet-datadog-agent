require 'spec_helper'

describe 'datadog_agent::integrations::docker_daemon' do
  context 'supported agents - v5 and v6' do
    agents = { '5' => false, '6' => true }
    agents.each do |_, enabled|
      let(:pre_condition) { "class {'::datadog_agent': agent6_enable => #{enabled}}" }
      let(:facts) {{
        operatingsystem: 'Ubuntu',
      }}
      if !enabled
        let(:conf_dir) { '/etc/dd-agent/conf.d' }
      else
        let(:conf_dir) { '/etc/datadog-agent/conf.d' }
      end
      let(:dd_user) { 'dd-agent' }
      let(:dd_group) { 'root' }
      let(:dd_package) { 'datadog-agent' }
      let(:dd_service) { 'datadog-agent' }
      if !enabled
        let(:conf_file) { "#{conf_dir}/docker_daemon.yaml" }
      else
        let(:conf_file) { "#{conf_dir}/docker.yaml" }
      end

      it { should compile.with_all_deps }
      it { should contain_file(conf_file).with(
        owner: dd_user,
        group: dd_group,
        mode: '0644',
      )}
      it { should contain_file(conf_file).that_requires("Package[#{dd_package}]") }
      it { should contain_file(conf_file).that_notifies("Service[#{dd_service}]") }

      context 'with default parameters' do
        it { should contain_file(conf_file).with_content(%r{url: unix://var/run/docker.sock}) }
      end

      context 'with parameters set' do
        let(:params) {{
          url: 'unix://foo/bar/baz.sock',
        }}
        it { should contain_file(conf_file).with_content(%r{url: unix://foo/bar/baz.sock}) }
      end

      context 'with tags parameter array' do
        let(:params) {{
          tags: %w{ foo bar baz },
        }}
        it { should contain_file(conf_file).with_content(%r{tags: \["foo", "bar", "baz"\]}) }
      end

      context 'with tags parameter with an empty tag' do
      end

      context 'with tags parameter empty values' do
        context 'mixed in with other tags' do
          let(:params) {{
            tags: [ 'foo', '', 'baz' ]
          }}

          it { should contain_file(conf_file).with_content(%r{tags: \["foo", "baz"\]}) }
        end

        context 'single element array of an empty string' do
          let(:params) {{
            tags: [''],
          }}

          it { should contain_file(conf_file).with_content(%r{tags: \[\]}) }
        end

        context 'single value empty string' do
          let(:params) {{
            tags: '',
          }}

          it { should contain_file(conf_file).with_content(%r{tags: \[\]}) }
        end
      end
    end
  end
end
